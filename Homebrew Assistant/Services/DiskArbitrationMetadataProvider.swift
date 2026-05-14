//
//  DiskArbitrationMetadataProvider.swift
//  Homebrew Assistant
//
//  Purpose: Resolves mounted-volume metadata using Disk Arbitration and URL
//  resource values.
//  Owns: Native Disk Arbitration session/disk lookup, Disk Arbitration
//  description mapping, and capacity lookup from volume resource values.
//  Does not own: SD card readiness classification, scoped filesystem access,
//  UI presentation, workflow navigation, file writes, or preparation state.
//  Uses: Disk Arbitration, URL resource values, DiskMetadataProvider, and
//  DiskVolumeMetadata.
//

import DiskArbitration
import Foundation

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
