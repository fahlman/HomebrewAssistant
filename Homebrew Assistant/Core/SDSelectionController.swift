//
//  SDSelectionController.swift
//  Homebrew Assistant
//
//  Purpose: Coordinates SD card selection state and SD selection bottom-bar
//  action policy for the active workflow session.
//  Owns: SD card picker presentation state, selected-volume scoped access,
//  selected drive display state, selected-volume readiness, selection error
//  state, SD card selection reset, Disk Utility launch intent tracking, and SD
//  selection bottom-bar configuration.
//  Does not own: SD card selection UI layout, bottom button placement, native
//  volume metadata lookup policy, file writes, staging, recipe preparation, or
//  workflow navigation.
//  Uses: ScopedAccessManager for scoped filesystem access, SDCardValidationService
//  for SD card readiness classification, and AppKit to open Disk Utility.
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

    init() {
        self.scopedAccessManager = ScopedAccessManager()
        self.sdCardValidationService = SDCardValidationService()
    }

    init(
        scopedAccessManager: ScopedAccessManager,
        sdCardValidationService: SDCardValidationService
    ) {
        self.scopedAccessManager = scopedAccessManager
        self.sdCardValidationService = sdCardValidationService
    }

    var selectedVolumeURL: URL? {
        scopedAccessManager.selectedVolumeURL
    }

    var bottomBarConfiguration: WorkflowBottomBarConfiguration {
        let contextualActions = bottomBarActions

        return WorkflowBottomBarConfiguration(
            contextualActions: contextualActions,
            defaultAction: defaultBottomBarAction(for: contextualActions)
        )
    }

    private var bottomBarActions: [WorkflowStepAction] {
        var actions: [WorkflowStepAction] = []

        if shouldOfferDiskUtility {
            actions.append(
                WorkflowStepAction(
                    titleKey: "sdSelection.openDiskUtility.button",
                    systemImageName: "externaldrive.badge.gearshape"
                ) { [weak self] in
                    self?.openDiskUtility()
                }
            )
        }

        actions.append(
            WorkflowStepAction(
                titleKey: "sdSelection.chooseSDCard.button",
                systemImageName: "sdcard"
            ) { [weak self] in
                self?.presentVolumeImporter()
            }
        )

        return actions
    }

    private func defaultBottomBarAction(for contextualActions: [WorkflowStepAction]) -> WorkflowBottomBarConfiguration.DefaultAction? {
        if readiness?.isReady == true {
            return .next
        }

        if shouldOfferDiskUtility && !hasOpenedDiskUtilityForCurrentSelection {
            return .contextualAction(index: contextualActions.startIndex)
        }

        return .contextualAction(index: contextualActions.index(before: contextualActions.endIndex))
    }

    private var shouldOfferDiskUtility: Bool {
        guard case .unavailable(reason: .unsupportedFileSystem, metadata: _) = readiness else {
            return false
        }

        return true
    }

    private func openDiskUtility() {
        hasOpenedDiskUtilityForCurrentSelection = true
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: "/System/Applications/Utilities/Disk Utility.app"),
            configuration: .init()
        )
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

