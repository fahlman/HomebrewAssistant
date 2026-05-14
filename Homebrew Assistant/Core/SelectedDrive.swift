//
//  SelectedDrive.swift
//  Homebrew Assistant
//
//  Purpose: Represents the currently selected drive shown in the SD card
//  selection step.
//  Owns: Selected volume URL, display name, and readiness result associated with
//  the selected volume.
//  Does not own: Scoped access lifecycle, native metadata lookup, readiness
//  validation policy, Disk Utility launch behavior, SwiftUI layout, file writes,
//  workflow navigation, or bottom-bar behavior.
//  Used by: SDSelectionController and DriveSelectionPresentation.
//

import Foundation

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
