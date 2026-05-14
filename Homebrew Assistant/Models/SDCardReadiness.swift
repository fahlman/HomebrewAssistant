//
//  SDCardReadiness.swift
//  Homebrew Assistant
//
//  Purpose: Represents readiness validation results for a selected SD card volume.
//  Owns: Ready/unavailable validation state, readiness convenience, failure
//  reasons including internal-disk rejection, and optional disk metadata for
//  invalid but readable selected volumes.
//  Does not own: Disk metadata queries, scoped access, UI copy, workflow
//  navigation, file writes, or preflight write/read/delete verification.
//  Consumed by: SDCardValidationService, SDSelectionController, and views that
//  need selected SD card readiness state.
//

import Foundation

nonisolated enum SDCardReadiness: Equatable {
    case ready(DiskVolumeMetadata)
    case unavailable(reason: SDCardReadinessFailureReason, metadata: DiskVolumeMetadata? = nil)

    var isReady: Bool {
        guard case .ready = self else {
            return false
        }

        return true
    }
}

nonisolated enum SDCardReadinessFailureReason: Equatable {
    case metadataUnavailable
    case notSecureDigital
    case internalDisk
    case unsupportedFileSystem
    case notWritable
}
