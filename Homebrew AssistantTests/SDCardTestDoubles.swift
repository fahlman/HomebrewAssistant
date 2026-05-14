//
//  SDCardTestDoubles.swift
//  Homebrew Assistant Tests
//
//  Purpose: Provides shared SD-card-related test doubles and metadata factories.
//  Owns: Mutable disk metadata provider, fake Disk Utility opener, and fake
//  security-scoped access session/factory implementations, and common SD card
//  metadata fixtures.
//  Does not own: Production disk metadata lookup, AppKit launching, scoped
//  access behavior, SD card validation policy, or test assertions.
//

import Foundation
@testable import Homebrew_Assistant

final class MutableDiskMetadataProvider: DiskMetadataProvider {
    var metadata: DiskVolumeMetadata?

    init(metadata: DiskVolumeMetadata?) {
        self.metadata = metadata
    }

    func metadata(for volumeURL: URL) -> DiskVolumeMetadata? {
        metadata
    }
}

final class FakeDiskUtilityOpener: DiskUtilityOpening {
    private(set) var didOpenDiskUtility = false

    func openDiskUtility() {
        didOpenDiskUtility = true
    }
}

struct FakeSecurityScopedAccessSessionFactory: SecurityScopedAccessSessionFactory {
    func makeSession(for volumeURL: URL) -> (any SecurityScopedAccessSession)? {
        FakeSecurityScopedAccessSession(volumeURL: volumeURL)
    }
}

final class FakeSecurityScopedAccessSession: SecurityScopedAccessSession {
    let volumeURL: URL
    private(set) var didStop = false

    init(volumeURL: URL) {
        self.volumeURL = volumeURL
    }

    func stop() {
        didStop = true
    }
}

func readySecureDigitalMetadata(for volumeURL: URL) -> DiskVolumeMetadata {
    DiskVolumeMetadata(
        volumeURL: volumeURL,
        localizedName: "Test SD",
        protocolName: "Secure Digital",
        fileSystemType: "msdos",
        isWritable: true,
        isRemovable: true,
        isEjectable: true,
        isInternal: false
    )
}

func unsupportedFilesystemSecureDigitalMetadata(for volumeURL: URL) -> DiskVolumeMetadata {
    DiskVolumeMetadata(
        volumeURL: volumeURL,
        localizedName: "Test SD",
        protocolName: "Secure Digital",
        fileSystemType: "apfs",
        isWritable: true,
        isRemovable: true,
        isEjectable: true,
        isInternal: false
    )
}
