//
//  WorkflowSessionControllerTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies active workflow session controller wiring.
//  Covers: Session controller construction, selected-step bottom-bar state
//  snapshots, synchronization from SD card readiness into fixed workflow-step
//  completion state, and synchronization from Choose Homebrew dashboard
//  completion into fixed workflow-step completion state.
//  Does not cover: SwiftUI layout, sidebar rendering, native button rendering,
//  native scoped access, native disk metadata lookup, downloads, staging, or
//  file writes.
//

import Foundation
import Testing
@testable import Homebrew_Assistant

@MainActor
struct WorkflowSessionControllerTests {
    @Test func sessionCreatesSharedControllers() {
        let sessionController = WorkflowSessionController()

        #expect(sessionController.coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems)
        ])
        #expect(sessionController.sdSelectionController.readiness == nil)
        #expect(sessionController.homebrewDashboardController.visibleOptions.map(\.source) == [
            .builtIn(.wilbrand),
            .builtIn(.hackMii)
        ])
    }

    @Test func readySDCardSelectionCompletesFixedSDCardStep() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: readySecureDigitalMetadata(for: volumeURL))

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))

        #expect(sessionController.coordinator.isCompleted(.fixed(.sdCardSelection)))
        #expect(sessionController.coordinator.canSelect(.fixed(.chooseItems)))
    }

    @Test func readySDCardSelectionMakesNextTheDefaultBottomBarAction() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: readySecureDigitalMetadata(for: volumeURL))

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))

        #expect(sessionController.bottomBarState.canGoForward)
        #expect(sessionController.bottomBarState.configuration.defaultAction == .next)
    }

    @Test func unavailableSDCardSelectionDoesNotCompleteFixedSDCardStep() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: unsupportedFilesystemSecureDigitalMetadata(for: volumeURL))

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))

        #expect(!sessionController.coordinator.isCompleted(.fixed(.sdCardSelection)))
        #expect(!sessionController.coordinator.canSelect(.fixed(.chooseItems)))
        #expect(sessionController.coordinator.state(for: .fixed(.sdCardSelection)).status == .failed)
    }

    @Test func unavailableSDCardSelectionOffersDiskUtilityBeforeChooseSDCard() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: unsupportedFilesystemSecureDigitalMetadata(for: volumeURL))

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))

        #expect(!sessionController.bottomBarState.canGoForward)
        #expect(sessionController.bottomBarState.configuration.contextualActions.map(\.titleKey) == [
            "sdSelection.openDiskUtility.button",
            "sdSelection.chooseSDCard.button"
        ])
        #expect(sessionController.bottomBarState.configuration.contextualActions.map(\.systemImageName) == [
            "externaldrive.badge.gearshape",
            "sdcard"
        ])
        #expect(sessionController.bottomBarState.configuration.defaultAction == .contextualAction(index: 0))
    }

    @Test func openingDiskUtilityImmediatelyUpdatesSDSelectionBottomBarState() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: unsupportedFilesystemSecureDigitalMetadata(for: volumeURL))

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        sessionController.bottomBarState.configuration.contextualActions.first?.perform()

        #expect(sessionController.sdSelectionController.actionState == .unsupportedFilesystem(hasOpenedDiskUtility: true))
        #expect(sessionController.bottomBarState.configuration.defaultAction == .contextualAction(index: 1))
    }

    @Test func changingFromReadyToUnavailableInvalidatesFixedSDCardStep() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let metadataProvider = MutableDiskMetadataProvider(metadata: readySecureDigitalMetadata(for: volumeURL))
        let sessionController = makeSessionController(metadataProvider: metadataProvider)

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        #expect(sessionController.coordinator.isCompleted(.fixed(.sdCardSelection)))

        metadataProvider.metadata = unsupportedFilesystemSecureDigitalMetadata(for: volumeURL)
        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))

        #expect(!sessionController.coordinator.isCompleted(.fixed(.sdCardSelection)))
        #expect(sessionController.coordinator.selectedItemID == WorkflowItem.fixed(.sdCardSelection).id)
    }

    @Test func returningToDiskAccessRevalidatesSelectedSDCard() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let metadataProvider = MutableDiskMetadataProvider(metadata: readySecureDigitalMetadata(for: volumeURL))
        let sessionController = makeSessionController(metadataProvider: metadataProvider)

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        sessionController.goForward()
        #expect(sessionController.coordinator.selectedItem == .fixed(.chooseItems))

        metadataProvider.metadata = unsupportedFilesystemSecureDigitalMetadata(for: volumeURL)
        sessionController.goBack()

        #expect(sessionController.coordinator.selectedItem == .fixed(.sdCardSelection))
        #expect(sessionController.sdSelectionController.readiness == .unavailable(
            reason: .unsupportedFileSystem,
            metadata: unsupportedFilesystemSecureDigitalMetadata(for: volumeURL)
        ))
        #expect(!sessionController.coordinator.isCompleted(.fixed(.sdCardSelection)))
        #expect(!sessionController.coordinator.canSelect(.fixed(.chooseItems)))
        #expect(!sessionController.bottomBarState.canGoForward)
    }

    @Test func movingToChooseHomebrewRefreshesBottomBarState() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: readySecureDigitalMetadata(for: volumeURL))

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        sessionController.goForward()

        #expect(sessionController.coordinator.selectedItem == .fixed(.chooseItems))
        #expect(sessionController.bottomBarState.canGoBack)
        #expect(!sessionController.bottomBarState.canGoForward)
        #expect(sessionController.bottomBarState.configuration.contextualActions.isEmpty)
        #expect(sessionController.bottomBarState.configuration.defaultAction == nil)
    }

    @Test func movingFromDiskAccessToChooseHomebrewReconcilesPreparedState() throws {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let payloadURL = URL(fileURLWithPath: "/tmp/hackmii.zip")
        let extractedURL = URL(fileURLWithPath: "/tmp/extracted/builtIn-hackMii")
        var reconciledStateStore = HomebrewPreparationStateStore()
        reconciledStateStore[HomebrewOptionID.builtIn(.hackMii)] = .readyToSave
        reconciledStateStore.setPreparedPayloadURL(
            payloadURL,
            for: HomebrewOptionID.builtIn(.hackMii)
        )
        reconciledStateStore.setExtractedPayloadDirectoryURL(
            extractedURL,
            for: HomebrewOptionID.builtIn(.hackMii)
        )
        let sessionController = makeSessionController(
            metadata: readySecureDigitalMetadata(for: volumeURL),
            preparationStateReconciler: FakeHomebrewPreparationStateReconciler(
                reconciledState: ReconciledHomebrewPreparationState(
                    selectedOptionIDs: [HomebrewOptionID.builtIn(.hackMii)],
                    preparationStateStore: reconciledStateStore
                )
            )
        )
        let hackMiiOption = try #require(sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.hackMii)
        })

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        sessionController.goForward()

        #expect(sessionController.homebrewDashboardController.isSelected(hackMiiOption))
        #expect(sessionController.homebrewDashboardController.status(for: hackMiiOption) == .readyToSave)
        #expect(sessionController.homebrewDashboardController.preparedPayloadURL(for: hackMiiOption) == payloadURL)
        #expect(sessionController.homebrewDashboardController.extractedPayloadDirectoryURL(for: hackMiiOption) == extractedURL)
        #expect(sessionController.bottomBarState.configuration.contextualActions.map(\.titleKey) == [
            HomebrewPreparationAction.save.titleKey
        ])
    }

    @Test func selectingChooseHomebrewStepReconcilesPreparedState() throws {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let payloadURL = URL(fileURLWithPath: "/tmp/hackmii.zip")
        let extractedURL = URL(fileURLWithPath: "/tmp/extracted/builtIn-hackMii")
        var reconciledStateStore = HomebrewPreparationStateStore()
        reconciledStateStore[HomebrewOptionID.builtIn(.hackMii)] = .readyToSave
        reconciledStateStore.setPreparedPayloadURL(
            payloadURL,
            for: HomebrewOptionID.builtIn(.hackMii)
        )
        reconciledStateStore.setExtractedPayloadDirectoryURL(
            extractedURL,
            for: HomebrewOptionID.builtIn(.hackMii)
        )
        let sessionController = makeSessionController(
            metadata: readySecureDigitalMetadata(for: volumeURL),
            preparationStateReconciler: FakeHomebrewPreparationStateReconciler(
                reconciledState: ReconciledHomebrewPreparationState(
                    selectedOptionIDs: [HomebrewOptionID.builtIn(.hackMii)],
                    preparationStateStore: reconciledStateStore
                )
            )
        )
        let hackMiiOption = try #require(sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.hackMii)
        })

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        sessionController.coordinator.select(.fixed(.chooseItems))

        #expect(sessionController.homebrewDashboardController.isSelected(hackMiiOption))
        #expect(sessionController.homebrewDashboardController.status(for: hackMiiOption) == .readyToSave)
        #expect(sessionController.homebrewDashboardController.preparedPayloadURL(for: hackMiiOption) == payloadURL)
        #expect(sessionController.homebrewDashboardController.extractedPayloadDirectoryURL(for: hackMiiOption) == extractedURL)
        #expect(sessionController.bottomBarState.configuration.contextualActions.map(\.titleKey) == [
            HomebrewPreparationAction.save.titleKey
        ])
    }

    @Test func selectingHomebrewDoesNotCompleteChooseHomebrewStep() {
        let sessionController = WorkflowSessionController()
        let hackMiiOption = sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        sessionController.homebrewDashboardController.setOption(hackMiiOption, isSelected: true)

        #expect(!sessionController.coordinator.isCompleted(.fixed(.chooseItems)))
        #expect(sessionController.coordinator.state(for: .fixed(.chooseItems)).status == .inProgress)
    }

    @Test func selectingSetupRequiredHomebrewMakesNamedSetupTheDefaultBottomBarAction() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: readySecureDigitalMetadata(for: volumeURL))
        let wilbrandOption = sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.wilbrand)
        }

        #expect(wilbrandOption != nil)
        guard let wilbrandOption else { return }

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        sessionController.goForward()
        sessionController.homebrewDashboardController.setOption(wilbrandOption, isSelected: true)

        #expect(sessionController.bottomBarState.canGoBack)
        #expect(!sessionController.bottomBarState.canGoForward)
        #expect(sessionController.bottomBarState.configuration.contextualActions.map(\.titleKey) == [
            HomebrewPreparationAction.setUp(optionName: "Wilbrand").titleKey
        ])
        #expect(sessionController.bottomBarState.configuration.contextualActions.map(\.titleArguments) == [
            HomebrewPreparationAction.setUp(optionName: "Wilbrand").titleArguments
        ])
        #expect(sessionController.bottomBarState.configuration.defaultAction == .contextualAction(index: 0))
    }

    @Test func completingSelectedHomebrewCompletesChooseHomebrewStep() async {
        let sessionController = makeSessionControllerWithReadyToSaveHackMii()
        let hackMiiOption = sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        sessionController.homebrewDashboardController.setOption(hackMiiOption, isSelected: true)
        await sessionController.homebrewDashboardController.perform(.save)

        #expect(sessionController.homebrewDashboardController.actionState == .complete)
        #expect(sessionController.coordinator.isCompleted(.fixed(.chooseItems)))
        #expect(sessionController.coordinator.state(for: .fixed(.chooseItems)).status == .completed)
    }

    @Test func failedHomebrewPreparationMarksChooseHomebrewStepFailed() async {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(
            metadata: readySecureDigitalMetadata(for: volumeURL),
            homebrewDashboardController: HomebrewDashboardController(
                builtInHomebrewCatalog: BuiltInHomebrewCatalog(definitions: [
                    downloadableHackMiiDefinition()
                ]),
                preparationExecutor: ImmediateHomebrewPreparationExecutor(
                    payloadDownloader: ThrowingHomebrewPayloadDownloader(),
                    archiveExtractor: FakeHomebrewArchiveExtractor()
                )
            )
        )
        let hackMiiOption = sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        sessionController.goForward()
        sessionController.homebrewDashboardController.setOption(hackMiiOption, isSelected: true)
        await sessionController.homebrewDashboardController.perform(.download)

        #expect(sessionController.homebrewDashboardController.actionState == .failed)
        #expect(sessionController.coordinator.state(for: .fixed(.chooseItems)).status == .failed)
    }

    @Test func busyHomebrewPreparationDisablesForwardAndContextualActions() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(
            metadata: readySecureDigitalMetadata(for: volumeURL),
            homebrewDashboardController: downloadingHackMiiController()
        )

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        sessionController.goForward()

        #expect(sessionController.homebrewDashboardController.actionState == .downloading)
        #expect(!sessionController.bottomBarState.canGoForward)
        #expect(sessionController.bottomBarState.configuration.canGoForwardOverride == false)
        #expect(sessionController.bottomBarState.configuration.contextualActions.isEmpty)
    }

    @Test func completedSelectedHomebrewClearsDashboardBottomBarActions() async {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(
            metadata: readySecureDigitalMetadata(for: volumeURL),
            homebrewDashboardController: readyToSaveHackMiiController()
        )
        let hackMiiOption = sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        sessionController.goForward()
        sessionController.homebrewDashboardController.setOption(hackMiiOption, isSelected: true)
        await sessionController.homebrewDashboardController.perform(.save)

        #expect(!sessionController.bottomBarState.canGoForward)
        #expect(sessionController.bottomBarState.configuration.contextualActions.isEmpty)
        #expect(sessionController.bottomBarState.configuration.defaultAction == nil)
    }

    @Test func changingCompletedHomebrewSelectionInvalidatesChooseHomebrewStep() async {
        let sessionController = makeSessionControllerWithReadyToSaveHackMii()
        let hackMiiOption = sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.hackMii)
        }
        let wilbrandOption = sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.wilbrand)
        }

        #expect(hackMiiOption != nil)
        #expect(wilbrandOption != nil)
        guard let hackMiiOption, let wilbrandOption else { return }

        sessionController.homebrewDashboardController.setOption(hackMiiOption, isSelected: true)
        await sessionController.homebrewDashboardController.perform(.save)
        #expect(sessionController.coordinator.isCompleted(.fixed(.chooseItems)))

        sessionController.homebrewDashboardController.setOption(wilbrandOption, isSelected: true)

        #expect(sessionController.homebrewDashboardController.actionState == .needsSetup(optionName: "Wilbrand"))
        #expect(!sessionController.coordinator.isCompleted(.fixed(.chooseItems)))
    }

    private func makeSessionControllerWithDownloadableHackMii() -> WorkflowSessionController {
        makeSessionController(
            metadataProvider: MutableDiskMetadataProvider(metadata: nil),
            homebrewDashboardController: downloadableHackMiiController()
        )
    }

    private func makeSessionControllerWithReadyToSaveHackMii() -> WorkflowSessionController {
        makeSessionController(
            metadataProvider: MutableDiskMetadataProvider(metadata: nil),
            homebrewDashboardController: readyToSaveHackMiiController()
        )
    }

    private func makeSessionController(
        metadata: DiskVolumeMetadata?,
        homebrewDashboardController: HomebrewDashboardController? = nil,
        preparationStateReconciler: (any HomebrewPreparationStateReconciling)? = nil
    ) -> WorkflowSessionController {
        makeSessionController(
            metadataProvider: MutableDiskMetadataProvider(metadata: metadata),
            homebrewDashboardController: homebrewDashboardController,
            preparationStateReconciler: preparationStateReconciler
        )
    }

    private func makeSessionController(
        metadataProvider: MutableDiskMetadataProvider,
        homebrewDashboardController: HomebrewDashboardController? = nil,
        preparationStateReconciler: (any HomebrewPreparationStateReconciling)? = nil
    ) -> WorkflowSessionController {
        let scopedAccessManager = ScopedAccessManager(accessSessionFactory: FakeSecurityScopedAccessSessionFactory())
        let sdCardValidationService = SDCardValidationService(metadataProvider: metadataProvider)
        let sdSelectionController = SDSelectionController(
            scopedAccessManager: scopedAccessManager,
            sdCardValidationService: sdCardValidationService,
            diskUtilityOpener: FakeDiskUtilityOpener()
        )

        return WorkflowSessionController(
            coordinator: WorkflowCoordinator(),
            sdSelectionController: sdSelectionController,
            homebrewDashboardController: homebrewDashboardController,
            preparationStateReconciler: preparationStateReconciler
        )
    }

    private func downloadableHackMiiController() -> HomebrewDashboardController {
        HomebrewDashboardController(
            builtInHomebrewCatalog: BuiltInHomebrewCatalog(definitions: [
                downloadableHackMiiDefinition()
            ]),
            preparationExecutor: ImmediateHomebrewPreparationExecutor(
                payloadDownloader: FakeHomebrewPayloadDownloader(),
                archiveExtractor: FakeHomebrewArchiveExtractor()
            )
        )
    }

    private func downloadingHackMiiController() -> HomebrewDashboardController {
        HomebrewDashboardController(
            builtInHomebrewCatalog: BuiltInHomebrewCatalog(definitions: [
                downloadableHackMiiDefinition()
            ]),
            preparationStateStore: preparationStateStore(
                optionID: HomebrewOptionID.builtIn(.hackMii),
                status: .downloading(progress: 0.5)
            ),
            selectedOptionIDs: [HomebrewOptionID.builtIn(.hackMii)]
        )
    }

    private func readyToSaveHackMiiController() -> HomebrewDashboardController {
        HomebrewDashboardController(
            builtInHomebrewCatalog: BuiltInHomebrewCatalog(),
            preparationStateStore: preparationStateStore(
                optionID: HomebrewOptionID.builtIn(.hackMii),
                status: .readyToSave
            )
        )
    }

    private func preparationStateStore(
        optionID: HomebrewOption.ID,
        status: HomebrewPreparationStatus
    ) -> HomebrewPreparationStateStore {
        var preparationStateStore = HomebrewPreparationStateStore()
        preparationStateStore[optionID] = status
        return preparationStateStore
    }

    private func downloadableHackMiiDefinition() -> HomebrewDefinition {
        HomebrewDefinition(
            id: HomebrewOptionID.builtIn(.hackMii),
            name: "HackMii",
            summaryKey: "chooseHomebrew.hackMii.description",
            category: .installers,
            systemImageName: "hammer",
            sortOrder: 101,
            preparationKind: .downloadable,
            downloadRequest: HomebrewDownloadRequest(
                approvedBaseURL: URL(string: "https://example.com/")!,
                payloadFileName: "hackmii.zip",
                expectedSHA256: "fake-test-downloader-does-not-read-this"
            ),
            source: .builtIn(.hackMii)
        )
    }
}
