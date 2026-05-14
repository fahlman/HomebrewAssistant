//
//  SDCardValidationService.swift
//  Homebrew Assistant
//
//  Purpose: Classifies SD card readiness from mounted-volume metadata.
//  Owns: Secure Digital protocol validation, FAT32 filesystem validation,
//  writable-volume validation, and SD card readiness classification.
//  Does not own: Disk metadata lookup, mounted-volume metadata modeling, scoped
//  filesystem access lifecycle, UI presentation, file copying, staging, recipe
//  preparation, workflow navigation, or workflow state transitions.
//  Uses: DiskMetadataProvider for mounted-volume metadata and SDCardReadiness
//  for readiness results.
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


        guard hasSupportedFileSystem(metadata.fileSystemType) else {
            return .unavailable(reason: .unsupportedFileSystem, metadata: metadata)
        }

        guard metadata.isWritable else {
            return .unavailable(reason: .notWritable, metadata: metadata)
        }

        return .ready(metadata)
    }
}

private extension SDCardValidationService {
    func hasSupportedFileSystem(_ fileSystemType: String?) -> Bool {
        guard let fileSystemType else {
            return false
        }

        return fileSystemType.localizedCaseInsensitiveCompare("msdos") == .orderedSame
            || fileSystemType.localizedCaseInsensitiveCompare("fat32") == .orderedSame
            || fileSystemType.localizedCaseInsensitiveCompare("ms-dos fat32") == .orderedSame
    }
}
