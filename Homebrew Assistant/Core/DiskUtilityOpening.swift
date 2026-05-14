//
//  DiskUtilityOpening.swift
//  Homebrew Assistant
//
//  Purpose: Defines the Disk Utility launch boundary used by SD card selection.
//  Owns: Disk Utility launch protocol and AppKit-backed production opener.
//  Does not own: SD card selection state, readiness validation, Disk Utility
//  process behavior, SwiftUI layout, file writes, workflow navigation, or tests.
//  Used by: SDSelectionController and SD card selection tests.
//

import AppKit
import Foundation

protocol DiskUtilityOpening {
    func openDiskUtility()
}

struct AppKitDiskUtilityOpener: DiskUtilityOpening {
    func openDiskUtility() {
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: "/System/Applications/Utilities/Disk Utility.app"),
            configuration: .init()
        )
    }
}
