//
//  WorkflowSessionController.swift
//  Homebrew Assistant
//
//  Purpose: Coordinates the active workflow session and cross-controller state
//  synchronization.
//  Owns: WorkflowCoordinator, SDSelectionController, HomebrewDashboardController,
//  selected-step bottom-bar state snapshots, navigation intent forwarding,
//  synchronization from SD card readiness into fixed workflow-step state, and
//  synchronization from dashboard action state into fixed workflow-step state.
//  Does not own: App launch, SwiftUI layout, sidebar rendering, detail-view
//  routing, bottom button rendering, SD card validation policy, scoped filesystem
//  access implementation, recipe loading, downloads, staging, or file writes.
//  Uses: WorkflowCoordinator, SDSelectionController, and
//  HomebrewDashboardController for session state.
//

import Combine
import Foundation

@MainActor
final class WorkflowSessionController: ObservableObject {
    let coordinator: WorkflowCoordinator
    let sdSelectionController: SDSelectionController
    let homebrewDashboardController: HomebrewDashboardController

    @Published private(set) var bottomBarState: WorkflowBottomBarState

    private let preparationStateReconciler: (any HomebrewPreparationStateReconciling)?
    private var cancellables: Set<AnyCancellable> = []

    static func makeForLaunchEnvironment(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> WorkflowSessionController {
        guard arguments.contains("--ui-testing") else {
            return WorkflowSessionController(reconcilePreparedHomebrew: true)
        }

        return makeUITestingSession(arguments: arguments)
    }

    init(reconcilePreparedHomebrew: Bool = false) {
        let coordinator = WorkflowCoordinator()
        let sdSelectionController = SDSelectionController()
        let preparationStateReconciler: (any HomebrewPreparationStateReconciling)? = reconcilePreparedHomebrew
            ? ApplicationSupportHomebrewPreparationReconciler()
            : nil

        self.coordinator = coordinator
        self.sdSelectionController = sdSelectionController
        self.homebrewDashboardController = HomebrewDashboardController()
        self.preparationStateReconciler = preparationStateReconciler
        self.bottomBarState = .initial
        bindSelectedStepDisplayChanges()
        bindHomebrewDashboardActionBottomBarChanges()
        bindSDSelectionReadinessToWorkflowState()
        bindSDSelectionActionBottomBarChanges()
        synchronizeWorkflowStepStates()
        synchronizeBottomBarState()
    }

    init(
        coordinator: WorkflowCoordinator,
        sdSelectionController: SDSelectionController,
        homebrewDashboardController: HomebrewDashboardController? = nil,
        preparationStateReconciler: (any HomebrewPreparationStateReconciling)? = nil
    ) {
        self.coordinator = coordinator
        self.sdSelectionController = sdSelectionController
        self.homebrewDashboardController = homebrewDashboardController ?? HomebrewDashboardController()
        self.preparationStateReconciler = preparationStateReconciler
        self.bottomBarState = .initial
        bindSelectedStepDisplayChanges()
        bindHomebrewDashboardActionBottomBarChanges()
        bindSDSelectionReadinessToWorkflowState()
        bindSDSelectionActionBottomBarChanges()
        synchronizeWorkflowStepStates()
        synchronizeBottomBarState()
    }

    func goBack() {
        coordinator.goBack()
    }

    func goForward() {
        coordinator.goForward()
    }

    private func handleSelectedStepChange(to selectedItem: WorkflowItem?) {
        switch selectedItem {
        case .fixed(.chooseItems):
            reconcilePreparedStateIfNeeded()
        case .fixed(.sdCardSelection):
            sdSelectionController.revalidateSelectedVolume()
        case nil:
            break
        }

        synchronizeBottomBarState()
    }

    private func reconcilePreparedStateIfNeeded() {
        guard let preparationStateReconciler else {
            return
        }

        homebrewDashboardController.reconcilePreparedState(using: preparationStateReconciler)
    }

    private func synchronizeWorkflowStepStates() {
        updateSDCardSelectionState(for: sdSelectionController.readiness)
        updateChooseHomebrewState(for: homebrewDashboardController.actionState)
    }

    private func bindSelectedStepDisplayChanges() {
        coordinator.selectedItemDidChange = { [weak self] selectedItem in
            self?.handleSelectedStepChange(to: selectedItem)
        }
    }

    private func bindHomebrewDashboardActionBottomBarChanges() {
        homebrewDashboardController.$actionState
            .dropFirst()
            .sink { [weak self] actionState in
                self?.updateChooseHomebrewState(for: actionState)
                self?.synchronizeBottomBarState(dashboardActionState: actionState)
            }
            .store(in: &cancellables)
    }

    private func bindSDSelectionReadinessToWorkflowState() {
        sdSelectionController.$readiness
            .dropFirst()
            .sink { [weak self] readiness in
                self?.updateSDCardSelectionState(for: readiness)
                self?.synchronizeBottomBarState()
            }
            .store(in: &cancellables)
    }

    private func bindSDSelectionActionBottomBarChanges() {
        sdSelectionController.$actionState
            .dropFirst()
            .sink { [weak self] actionState in
                self?.synchronizeBottomBarState(sdActionState: actionState)
            }
            .store(in: &cancellables)
    }

    private func synchronizeBottomBarState(
        sdActionState: SDSelectionActionState? = nil,
        dashboardActionState: HomebrewDashboardActionState? = nil
    ) {
        bottomBarState = WorkflowBottomBarState(
            canGoBack: coordinator.canGoBack,
            canGoForward: coordinator.canGoForward,
            configuration: selectedStepBottomBarConfiguration(
                sdActionState: sdActionState,
                dashboardActionState: dashboardActionState
            )
        )
    }

    private func selectedStepBottomBarConfiguration(
        sdActionState: SDSelectionActionState? = nil,
        dashboardActionState: HomebrewDashboardActionState? = nil
    ) -> WorkflowBottomBarConfiguration {
        switch coordinator.selectedItem {
        case .fixed(.sdCardSelection):
            if let sdActionState {
                return sdSelectionController.bottomBarConfiguration(for: sdActionState)
            }

            return sdSelectionController.bottomBarConfiguration
        case .fixed(.chooseItems):
            if let dashboardActionState {
                return homebrewDashboardController.bottomBarConfiguration(for: dashboardActionState)
            }

            return homebrewDashboardController.bottomBarConfiguration
        case nil:
            return .automatic
        }
    }

    private func updateSDCardSelectionState(for readiness: SDCardReadiness?) {
        let stepState = stepState(for: readiness)
        let isCompleted = readiness?.isReady == true
        if coordinator.isCompleted(.fixed(.sdCardSelection)) != isCompleted {
            coordinator.invalidateWorkflow(after: .fixed(.sdCardSelection))
            coordinator.setWorkflowItem(
                .fixed(.sdCardSelection),
                isCompleted: isCompleted
            )
        }
        coordinator.mark(.fixed(.sdCardSelection), as: stepState)
    }

    private func updateChooseHomebrewState(for actionState: HomebrewDashboardActionState) {
        let stepState = stepState(for: actionState)
        let isCompleted = stepState.status == .completed
        if coordinator.isCompleted(.fixed(.chooseItems)) != isCompleted {
            coordinator.setWorkflowItem(
                .fixed(.chooseItems),
                isCompleted: isCompleted
            )
        }
        coordinator.mark(.fixed(.chooseItems), as: stepState)
    }

    private func stepState(for readiness: SDCardReadiness?) -> StepState {
        switch readiness {
        case .ready:
            StepState(status: .completed)
        case .unavailable:
            StepState(status: .failed)
        case nil:
            StepState(status: .notStarted)
        }
    }

    private func stepState(for actionState: HomebrewDashboardActionState) -> StepState {
        return switch actionState {
        case .nothingSelected:
            StepState(status: .notStarted)
        case .needsSetup, .readyToDownload, .downloading, .readyToExtract, .extracting, .needsGeneratedArchiveFile, .readyToSave, .saving:
            StepState(status: .inProgress)
        case .failed:
            StepState(status: .failed)
        case .complete:
            StepState(status: .completed)
        }
    }
}

private extension WorkflowSessionController {
    static func makeUITestingSession(arguments: [String]) -> WorkflowSessionController {
        let volumeURL = URL(fileURLWithPath: "/Volumes/HomebrewAssistantUITestSD", isDirectory: true)
        let metadataProvider = UITestingDiskMetadataProvider(
            metadata: UITestingDiskMetadataProvider.readySecureDigitalMetadata(for: volumeURL)
        )
        let scopedAccessManager = ScopedAccessManager(
            accessSessionFactory: UITestingSecurityScopedAccessSessionFactory()
        )
        let sdSelectionController = SDSelectionController(
            scopedAccessManager: scopedAccessManager,
            sdCardValidationService: SDCardValidationService(metadataProvider: metadataProvider),
            diskUtilityOpener: UITestingDiskUtilityOpener()
        )
        let homebrewDashboardController = HomebrewDashboardController(
            preparationExecutor: ImmediateHomebrewPreparationExecutor(
                browserOpener: UITestingBrowserOpener()
            )
        )
        let sessionController = WorkflowSessionController(
            coordinator: WorkflowCoordinator(),
            sdSelectionController: sdSelectionController,
            homebrewDashboardController: homebrewDashboardController,
            preparationStateReconciler: nil
        )

        if arguments.contains("--ui-testing-ready-sd") {
            sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        }

        return sessionController
    }
}

private final class UITestingDiskUtilityOpener: DiskUtilityOpening {
    func openDiskUtility() {}
}

private final class UITestingDiskMetadataProvider: DiskMetadataProvider {
    let metadata: DiskVolumeMetadata?

    init(metadata: DiskVolumeMetadata?) {
        self.metadata = metadata
    }

    func metadata(for volumeURL: URL) -> DiskVolumeMetadata? {
        metadata
    }

    static func readySecureDigitalMetadata(for volumeURL: URL) -> DiskVolumeMetadata {
        DiskVolumeMetadata(
            volumeURL: volumeURL,
            localizedName: "UI Test SD",
            protocolName: "Secure Digital",
            fileSystemType: "msdos",
            isWritable: true,
            isRemovable: true,
            isEjectable: true,
            isInternal: false
        )
    }
}

private struct UITestingSecurityScopedAccessSessionFactory: SecurityScopedAccessSessionFactory {
    func makeSession(for volumeURL: URL) -> (any SecurityScopedAccessSession)? {
        UITestingSecurityScopedAccessSession()
    }
}

private final class UITestingSecurityScopedAccessSession: SecurityScopedAccessSession {
    let volumeURL = URL(fileURLWithPath: "/Volumes/HomebrewAssistantUITestSD", isDirectory: true)

    func stop() {}
}

private struct UITestingBrowserOpener: BrowserOpening {
    func open(_ url: URL) {}
}
