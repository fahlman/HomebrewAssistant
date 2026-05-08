//
//  SDCardReadiness.swift
//  Homebrew Assistant
//
//  Purpose: Represents readiness validation results for a selected SD card volume.
//  Owns: Ready/unavailable validation state, failure reasons, and optional
//  disk metadata for invalid but readable selected volumes.
//  Does not own: Disk metadata queries, scoped access, UI copy, workflow
//  navigation, file writes, or preflight write/read/delete verification.
//  Delegates to: DiskManager for construction and SDSelectionController / views
//  for consumption.
//

import Foundation

nonisolated enum SDCardReadiness: Equatable {
    case ready(DiskVolumeMetadata)
    case unavailable(reason: SDCardReadinessFailureReason, metadata: DiskVolumeMetadata? = nil)
}

nonisolated enum SDCardReadinessFailureReason: Equatable {
    case metadataUnavailable
    case notSecureDigital
    case unsupportedFileSystem
    case notWritable
}
