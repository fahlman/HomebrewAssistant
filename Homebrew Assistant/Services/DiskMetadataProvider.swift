//
//  DiskMetadataProvider.swift
//  Homebrew Assistant
//
//  Purpose: Defines the disk metadata lookup abstraction used by SD card
//  validation.
//  Owns: The protocol contract for resolving mounted-volume metadata by URL.
//  Does not own: Disk Arbitration lookup, metadata modeling, readiness
//  classification, scoped filesystem access, UI presentation, workflow
//  navigation, file writes, or preparation state.
//  Used by: SDCardValidationService, DiskArbitrationMetadataProvider, and tests.
//

import Foundation

protocol DiskMetadataProvider {
    func metadata(for volumeURL: URL) -> DiskVolumeMetadata?
}
