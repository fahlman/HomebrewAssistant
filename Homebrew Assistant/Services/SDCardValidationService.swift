//
//  SDCardValidationService.swift
//  Homebrew Assistant
//
//  Purpose: Classifies SD card readiness from mounted-volume metadata.
//  Owns: Secure Digital protocol validation, internal-disk rejection, FAT32
//  filesystem validation, writable-volume validation, and SD card readiness
//  classification.
//  Does not own: Disk metadata lookup, mounted-volume metadata modeling, scoped
//  filesystem access lifecycle, UI presentation, file copying, staging, recipe
//  preparation, workflow navigation, or workflow state transitions.
//  Uses: DiskMetadataProvider, DiskVolumeMetadata, and SDCardReadiness.
//

import Foundation

struct SDCardValidationService {
    private let metadataProvider: any DiskMetadataProvider

    init(metadataProvider: any DiskMetadataProvider = DiskArbitrationMetadataProvider()) {
        self.metadataProvider = metadataProvider
    }

    func readiness(for volumeURL: URL) -> SDCardReadiness {
        guard let metadata = metadataProvider.metadata(for: volumeURL) else {
            return .unavailable(reason: .metadataUnavailable)
        }

        guard metadata.protocolName == "Secure Digital" else {
            return .unavailable(reason: .notSecureDigital, metadata: metadata)
        }

        guard metadata.isInternal != true else {
            return .unavailable(reason: .internalDisk, metadata: metadata)
        }

        guard metadata.isFAT32 else {
            return .unavailable(reason: .unsupportedFileSystem, metadata: metadata)
        }

        guard metadata.isWritable else {
            return .unavailable(reason: .notWritable, metadata: metadata)
        }

        return .ready(metadata)
    }
}
