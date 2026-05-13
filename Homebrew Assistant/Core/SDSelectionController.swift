//
//  SDSelectionController.swift
//  Homebrew Assistant
//
//  Purpose: Coordinates SD card selection state and SD card selection bottom-bar
//  action policy for the active workflow session.
//  Owns: SD card picker presentation state, selected-volume scoped access,
//  selected drive display state, selected-volume readiness, selection error
//  state, SD card selection reset, Disk Utility launch intent tracking, SD card
//  selection action state, and SD card selection bottom-bar configuration.
//  Does not own: SD card selection UI layout, bottom-bar rendering, native
//  volume metadata lookup policy, file writes, staging, recipe preparation, or
//  workflow navigation.
//  Uses: ScopedAccessManager for scoped filesystem access, SDCardValidationService
//  for SD card readiness classification, and DiskUtilityOpening for Disk Utility
//  launch requests.
//

import AppKit
import Combine
import Foundation

@MainActor
final class SDSelectionController: ObservableObject {
    @Published var isVolumeImporterPresented = false
    @Published private(set) var readiness: SDCardReadiness?
    @Published private(set) var selectedDrive: SelectedDrive?
    @Published private(set) var selectionErrorMessage: String?
    @Published private(set) var hasOpenedDiskUtilityForCurrentSelection = false

    let scopedAccessManager: ScopedAccessManager

    private let sdCardValidationService: SDCardValidationService
    private let diskUtilityOpener: any DiskUtilityOpening

    init() {
        self.scopedAccessManager = ScopedAccessManager()
        self.sdCardValidationService = SDCardValidationService()
        self.diskUtilityOpener = AppKitDiskUtilityOpener()
    }

    convenience init(
        scopedAccessManager: ScopedAccessManager,
        sdCardValidationService: SDCardValidationService
    ) {
        self.init(
            scopedAccessManager: scopedAccessManager,
            sdCardValidationService: sdCardValidationService,
            diskUtilityOpener: AppKitDiskUtilityOpener()
        )
    }

    init(
        scopedAccessManager: ScopedAccessManager,
        sdCardValidationService: SDCardValidationService,
        diskUtilityOpener: any DiskUtilityOpening
    ) {
        self.scopedAccessManager = scopedAccessManager
        self.sdCardValidationService = sdCardValidationService
        self.diskUtilityOpener = diskUtilityOpener
    }

    var selectedVolumeURL: URL? {
        scopedAccessManager.selectedVolumeURL
    }

    var actionState: SDSelectionActionState {
        if readiness?.isReady == true {
            return .ready
        }

        if case .unavailable(reason: .unsupportedFileSystem, metadata: _) = readiness {
            return .unsupportedFilesystem(hasOpenedDiskUtility: hasOpenedDiskUtilityForCurrentSelection)
        }

        return .needsSelection
    }

    var bottomBarConfiguration: WorkflowBottomBarConfiguration {
        actionState.bottomBarConfiguration(controller: self)
    }

    func openDiskUtility() {
        hasOpenedDiskUtilityForCurrentSelection = true
        diskUtilityOpener.openDiskUtility()
    }

    func presentVolumeImporter() {
        isVolumeImporterPresented = true
    }

    func handleVolumeSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else {
                clearSelection()
                selectionErrorMessage = String(localized: "sdSelection.error.noVolumeSelected")
                return
            }

            validateSelectedVolume(selectedURL)
        case .failure:
            clearSelection()
            selectionErrorMessage = String(localized: "sdSelection.error.selectionFailed")
        }
    }

    func clearSelection() {
        scopedAccessManager.reset()
        readiness = nil
        selectedDrive = nil
        selectionErrorMessage = nil
        hasOpenedDiskUtilityForCurrentSelection = false
    }

    func reset() {
        clearSelection()
        isVolumeImporterPresented = false
    }

    private func validateSelectedVolume(_ selectedURL: URL) {
        hasOpenedDiskUtilityForCurrentSelection = false
        guard scopedAccessManager.startAccessing(selectedURL) else {
            clearSelection()
            selectionErrorMessage = String(localized: "sdSelection.error.scopedAccessFailed")
            return
        }

        let resolvedReadiness = sdCardValidationService.readiness(for: selectedURL)
        readiness = resolvedReadiness
        selectedDrive = SelectedDrive(volumeURL: selectedURL, readiness: resolvedReadiness)

        switch resolvedReadiness {
        case .ready:
            selectionErrorMessage = nil
        case .unavailable:
            selectionErrorMessage = nil
            scopedAccessManager.stopAccessingSelectedVolume()
        }
    }
}

protocol DiskUtilityOpening {
    func openDiskUtility()
}

private struct AppKitDiskUtilityOpener: DiskUtilityOpening {
    func openDiskUtility() {
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: "/System/Applications/Utilities/Disk Utility.app"),
            configuration: .init()
        )
    }
}

enum SDSelectionActionState: Equatable {
    case needsSelection
    case unsupportedFilesystem(hasOpenedDiskUtility: Bool)
    case ready

    func bottomBarConfiguration(controller: SDSelectionController) -> WorkflowBottomBarConfiguration {
        let contextualActions = contextualActions(controller: controller)

        return WorkflowBottomBarConfiguration(
            contextualActions: contextualActions,
            defaultAction: defaultAction(for: contextualActions)
        )
    }

    private func contextualActions(controller: SDSelectionController) -> [WorkflowStepAction] {
        switch self {
        case .needsSelection, .ready:
            [chooseSDCardAction(controller: controller)]
        case .unsupportedFilesystem:
            [
                openDiskUtilityAction(controller: controller),
                chooseSDCardAction(controller: controller)
            ]
        }
    }

    private func defaultAction(for contextualActions: [WorkflowStepAction]) -> WorkflowBottomBarConfiguration.DefaultAction? {
        switch self {
        case .ready:
            .next
        case .needsSelection:
            .contextualAction(index: contextualActions.startIndex)
        case .unsupportedFilesystem(let hasOpenedDiskUtility):
            hasOpenedDiskUtility
                ? .contextualAction(index: contextualActions.index(before: contextualActions.endIndex))
                : .contextualAction(index: contextualActions.startIndex)
        }
    }

    private func openDiskUtilityAction(controller: SDSelectionController) -> WorkflowStepAction {
        WorkflowStepAction(
            titleKey: "sdSelection.openDiskUtility.button",
            systemImageName: "externaldrive.badge.gearshape"
        ) { [weak controller] in
            controller?.openDiskUtility()
        }
    }

    private func chooseSDCardAction(controller: SDSelectionController) -> WorkflowStepAction {
        WorkflowStepAction(
            titleKey: "sdSelection.chooseSDCard.button",
            systemImageName: "sdcard"
        ) { [weak controller] in
            controller?.presentVolumeImporter()
        }
    }
}

struct SelectedDrive: Equatable, Sendable {
    let volumeURL: URL
    let displayName: String
    let readiness: SDCardReadiness

    init(volumeURL: URL, readiness: SDCardReadiness) {
        self.volumeURL = volumeURL
        self.readiness = readiness

        switch readiness {
        case .ready(let metadata):
            self.displayName = metadata.displayName
        case .unavailable(_, let metadata):
            self.displayName = metadata?.displayName ?? volumeURL.lastPathComponent
        }
    }
}
