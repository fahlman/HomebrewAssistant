//
//  DiskManager.swift
//  Homebrew Assistant
//
//  Purpose: Resolves native metadata for a user-selected mounted volume and classifies SD card readiness.
//  Owns: Mounted-volume metadata lookup, Secure Digital protocol validation,
//  writable-volume validation, and SD card readiness classification.
//  Does not own: Scoped filesystem access lifecycle, UI presentation, file copying,
//  staging, recipe preparation, or workflow navigation.
//  Delegates to: DiskMetadataProvider for native metadata lookup and WorkflowCoordinator
//  for workflow state transitions.
//

import Foundation
import DiskArbitration

struct DiskManager {
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

        guard metadata.isWritable else {
            return .unavailable(reason: .notWritable, metadata: metadata)
        }

        return .ready(metadata)
    }
}

protocol DiskMetadataProvider {
    func metadata(for volumeURL: URL) -> DiskVolumeMetadata?
}

struct DiskVolumeMetadata: Equatable, Sendable {
    let volumeURL: URL
    let localizedName: String?
    let displayName: String
    let protocolName: String?
    let isWritable: Bool
    let isRemovable: Bool?
    let isEjectable: Bool?
    let isInternal: Bool?

    init(
        volumeURL: URL,
        localizedName: String? = nil,
        displayName: String? = nil,
        protocolName: String? = nil,
        isWritable: Bool,
        isRemovable: Bool? = nil,
        isEjectable: Bool? = nil,
        isInternal: Bool? = nil
    ) {
        self.volumeURL = volumeURL
        self.localizedName = localizedName
        self.displayName = displayName ?? localizedName ?? volumeURL.lastPathComponent
        self.protocolName = protocolName
        self.isWritable = isWritable
        self.isRemovable = isRemovable
        self.isEjectable = isEjectable
        self.isInternal = isInternal
    }
}

enum SDCardReadiness: Equatable {
    case ready(DiskVolumeMetadata)
    case unavailable(reason: SDCardReadinessFailureReason, metadata: DiskVolumeMetadata? = nil)
}

enum SDCardReadinessFailureReason: Equatable {
    case metadataUnavailable
    case notSecureDigital
    case notWritable
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
        let isWritable = (description[kDADiskDescriptionMediaWritableKey as String] as? Bool) ?? false
        let isRemovable = description[kDADiskDescriptionMediaRemovableKey as String] as? Bool
        let isEjectable = description[kDADiskDescriptionMediaEjectableKey as String] as? Bool
        let isInternal = description[kDADiskDescriptionDeviceInternalKey as String] as? Bool

        return DiskVolumeMetadata(
            volumeURL: volumeURL,
            localizedName: localizedName,
            displayName: displayName,
            protocolName: protocolName,
            isWritable: isWritable,
            isRemovable: isRemovable,
            isEjectable: isEjectable,
            isInternal: isInternal
        )
    }
}
