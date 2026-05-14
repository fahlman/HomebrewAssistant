//
//  DiskVolumeMetadata.swift
//  Homebrew Assistant
//
//  Purpose: Models native metadata for a mounted disk volume.
//  Owns: Mounted-volume metadata values and display-name fallback.
//  Does not own: Disk Arbitration lookup, scoped filesystem access, readiness
//  classification, UI presentation, workflow navigation, file writes, or
//  preparation state.
//  Used by: DiskMetadataProvider, DiskArbitrationMetadataProvider,
//  SDCardValidationService, SDCardReadiness, and selected-drive presentation.
//

import Foundation

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

