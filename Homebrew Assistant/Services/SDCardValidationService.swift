//
//  SDCardValidationService.swift
//  Homebrew Assistant
//
//  Purpose: Resolves native metadata for a user-selected mounted volume and
//  classifies SD card readiness.
//  Owns: Disk metadata provider protocol, Disk Arbitration metadata lookup,
//  mounted-volume metadata modeling, Secure Digital protocol validation, FAT32
//  filesystem validation, writable-volume validation, and SD card readiness
//  classification.
//  Does not own: Scoped filesystem access lifecycle, UI presentation, file copying,
//  staging, recipe preparation, workflow navigation, or workflow state transitions.
//  Uses: Disk Arbitration and URL resource values for mounted-volume metadata.
//

import Foundation
import DiskArbitration

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

        guard metadata.isFAT32 else {
            return .unavailable(reason: .unsupportedFileSystem, metadata: metadata)
        }

        guard metadata.isWritable else {
            return .unavailable(reason: .notWritable, metadata: metadata)
        }

        return .ready(metadata)
    }
}

protocol DiskMetadataProvider {
    func metadata(for volumeURL: URL) -> DiskVolumeMetadata?
}

nonisolated struct DiskVolumeMetadata: Equatable, Sendable {
    let volumeURL: URL
    let localizedName: String?
    let displayName: String
    let protocolName: String?
    let fileSystemType: String?
    let totalCapacityBytes: Int64?
    let availableCapacityBytes: Int64?
    let isWritable: Bool
    let isRemovable: Bool?
    let isEjectable: Bool?
    let isInternal: Bool?

    init(
        volumeURL: URL,
        localizedName: String? = nil,
        displayName: String? = nil,
        protocolName: String? = nil,
        fileSystemType: String? = nil,
        totalCapacityBytes: Int64? = nil,
        availableCapacityBytes: Int64? = nil,
        isWritable: Bool,
        isRemovable: Bool? = nil,
        isEjectable: Bool? = nil,
        isInternal: Bool? = nil
    ) {
        self.volumeURL = volumeURL
        self.localizedName = localizedName
        self.displayName = displayName ?? localizedName ?? volumeURL.lastPathComponent
        self.protocolName = protocolName
        self.fileSystemType = fileSystemType
        self.totalCapacityBytes = totalCapacityBytes
        self.availableCapacityBytes = availableCapacityBytes
        self.isWritable = isWritable
        self.isRemovable = isRemovable
        self.isEjectable = isEjectable
        self.isInternal = isInternal
    }
}


private extension DiskVolumeMetadata {
    var isFAT32: Bool {
        guard let fileSystemType else {
            return false
        }

        return fileSystemType.localizedCaseInsensitiveCompare("msdos") == .orderedSame
            || fileSystemType.localizedCaseInsensitiveCompare("fat32") == .orderedSame
            || fileSystemType.localizedCaseInsensitiveCompare("ms-dos fat32") == .orderedSame
    }
}


struct DiskArbitrationMetadataProvider: DiskMetadataProvider {
    func metadata(for volumeURL: URL) -> DiskVolumeMetadata? {
        guard let session = DASessionCreate(kCFAllocatorDefault) else {
            return nil
        }

        guard let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, volumeURL as CFURL) else {
            return nil
        }

        guard let description = DADiskCopyDescription(disk) as? [String: Any] else {
            return nil
        }

        let localizedName = description[kDADiskDescriptionVolumeNameKey as String] as? String
        let displayName = localizedName ?? volumeURL.lastPathComponent
        let protocolName = description[kDADiskDescriptionDeviceProtocolKey as String] as? String
        let fileSystemType = description[kDADiskDescriptionVolumeKindKey as String] as? String
        let volumeResourceValues = try? volumeURL.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey
        ])
        let totalCapacityBytes = volumeResourceValues?.volumeTotalCapacity.map(Int64.init)
        let availableCapacityBytes = volumeResourceValues?.volumeAvailableCapacity.map(Int64.init)
        let isWritable = (description[kDADiskDescriptionMediaWritableKey as String] as? Bool) ?? false
        let isRemovable = description[kDADiskDescriptionMediaRemovableKey as String] as? Bool
        let isEjectable = description[kDADiskDescriptionMediaEjectableKey as String] as? Bool
        let isInternal = description[kDADiskDescriptionDeviceInternalKey as String] as? Bool

        return DiskVolumeMetadata(
            volumeURL: volumeURL,
            localizedName: localizedName,
            displayName: displayName,
            protocolName: protocolName,
            fileSystemType: fileSystemType,
            totalCapacityBytes: totalCapacityBytes,
            availableCapacityBytes: availableCapacityBytes,
            isWritable: isWritable,
            isRemovable: isRemovable,
            isEjectable: isEjectable,
            isInternal: isInternal
        )
    }
}
