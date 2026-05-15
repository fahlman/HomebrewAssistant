//
//  SDSelectionController.swift
//  Homebrew Assistant
//
//  Purpose: Coordinates SD card selection state and SD card selection bottom-bar
//  action policy for the active workflow session.
//  Owns: SD card picker presentation state, selected-volume scoped access,
//  selected drive display state, selected-volume readiness, selection error
//  state, SD card selection reset, Disk Utility launch intent tracking, SD card
//  selection action state, deterministic action-state derivation, and SD card
//  selection bottom-bar configuration.
//  Does not own: SD card selection UI layout, bottom-bar rendering, native
//  volume metadata lookup policy, file writes, staging, recipe preparation, or
//  workflow navigation.
//  Uses: ScopedAccessManager for scoped filesystem access, SDCardValidationService
//  for SD card readiness classification, and DiskUtilityOpening for Disk Utility
//  launch requests.
//

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
        actionState(for: readiness)
    }

    var bottomBarConfiguration: WorkflowBottomBarConfiguration {
        actionState.bottomBarConfiguration(controller: self)
    }

    func bottomBarConfiguration(for readiness: SDCardReadiness?) -> WorkflowBottomBarConfiguration {
        actionState(for: readiness).bottomBarConfiguration(controller: self)
    }

    private func actionState(for readiness: SDCardReadiness?) -> SDSelectionActionState {
        if readiness?.isReady == true {
            return .ready
        }

        if case .unavailable(reason: .unsupportedFileSystem, metadata: _) = readiness {
            return .unsupportedFilesystem(hasOpenedDiskUtility: hasOpenedDiskUtilityForCurrentSelection)
        }

        return .needsSelection
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

