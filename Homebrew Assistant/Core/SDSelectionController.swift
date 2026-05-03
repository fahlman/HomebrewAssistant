//
//  SDSelectionController.swift
//  Homebrew Assistant
//
//  Purpose: Coordinates SD card selection state for the active workflow session.
//  Owns: SD card picker presentation state, selected-volume scoped access,
//  selected/rejected drive display state, selected-volume readiness, selection
//  error state, and SD card selection reset.
//  Does not own: SD card selection UI layout, bottom button placement, Disk
//  Arbitration metadata policy, file writes, staging, recipe preparation, or
//  workflow navigation.
//  Delegates to: ScopedAccessManager for scoped filesystem access and DiskManager
//  for SD card readiness classification.
//

import Foundation
import Combine

@MainActor
final class SDSelectionController: ObservableObject {
    @Published var isVolumeImporterPresented = false
    @Published private(set) var readiness: SDCardReadiness?
    @Published private(set) var selectedDrive: SelectedDrive?
    @Published private(set) var selectionErrorMessage: String?

    let scopedAccessManager: ScopedAccessManager

    private let diskManager: DiskManager

    init() {
        self.scopedAccessManager = ScopedAccessManager()
        self.diskManager = DiskManager()
    }

    init(
        scopedAccessManager: ScopedAccessManager,
        diskManager: DiskManager
    ) {
        self.scopedAccessManager = scopedAccessManager
        self.diskManager = diskManager
    }

    var selectedVolumeURL: URL? {
        scopedAccessManager.selectedVolumeURL
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
    }

    func reset() {
        clearSelection()
        isVolumeImporterPresented = false
    }

    private func validateSelectedVolume(_ selectedURL: URL) {
        guard scopedAccessManager.startAccessing(selectedURL) else {
            clearSelection()
            selectionErrorMessage = String(localized: "sdSelection.error.scopedAccessFailed")
            return
        }

        let resolvedReadiness = diskManager.readiness(for: selectedURL)
        readiness = resolvedReadiness
        selectedDrive = SelectedDrive(volumeURL: selectedURL, readiness: resolvedReadiness)

        switch resolvedReadiness {
        case .ready:
            selectionErrorMessage = nil
        case .unavailable(let reason, _):
            selectionErrorMessage = reason.displayMessage
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

private extension SDCardReadinessFailureReason {
    var displayMessage: String {
        switch self {
        case .metadataUnavailable:
            String(localized: "sdSelection.readiness.metadataUnavailable")
        case .notSecureDigital:
            String(localized: "sdSelection.readiness.notSecureDigital")
        case .notWritable:
            String(localized: "sdSelection.readiness.notWritable")
        }
    }
}
