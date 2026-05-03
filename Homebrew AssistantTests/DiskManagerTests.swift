import Foundation
import Testing
@testable import Homebrew_Assistant

struct DiskManagerTests {
    @Test func metadataUnavailableReturnsMetadataUnavailable() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let manager = DiskManager(metadataProvider: FakeDiskMetadataProvider(metadata: nil))

        #expect(manager.readiness(for: volumeURL) == .unavailable(reason: .metadataUnavailable))
    }

    @Test func nilProtocolReturnsNotSecureDigital() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let manager = DiskManager(metadataProvider: FakeDiskMetadataProvider(metadata: DiskVolumeMetadata(
            volumeURL: volumeURL,
            protocolName: nil,
            isWritable: true,
            isRemovable: true,
            isEjectable: true,
            isInternal: false
        )))

        #expect(manager.readiness(for: volumeURL) == .unavailable(reason: .notSecureDigital))
    }

    @Test func nonSecureDigitalProtocolReturnsNotSecureDigital() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/USBDrive")
        let manager = DiskManager(metadataProvider: FakeDiskMetadataProvider(metadata: DiskVolumeMetadata(
            volumeURL: volumeURL,
            protocolName: "USB",
            isWritable: true,
            isRemovable: true,
            isEjectable: true,
            isInternal: false
        )))

        #expect(manager.readiness(for: volumeURL) == .unavailable(reason: .notSecureDigital))
    }

    @Test func secureDigitalButReadOnlyReturnsNotWritable() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let manager = DiskManager(metadataProvider: FakeDiskMetadataProvider(metadata: DiskVolumeMetadata(
            volumeURL: volumeURL,
            protocolName: "Secure Digital",
            isWritable: false,
            isRemovable: true,
            isEjectable: true,
            isInternal: false
        )))

        #expect(manager.readiness(for: volumeURL) == .unavailable(reason: .notWritable))
    }

    @Test func secureDigitalAndWritableReturnsReady() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let metadata = DiskVolumeMetadata(
            volumeURL: volumeURL,
            localizedName: "Test SD",
            protocolName: "Secure Digital",
            isWritable: true,
            isRemovable: true,
            isEjectable: true,
            isInternal: false
        )
        let manager = DiskManager(metadataProvider: FakeDiskMetadataProvider(metadata: metadata))

        #expect(manager.readiness(for: volumeURL) == .ready(metadata))
    }

    @Test func removableEjectableExternalTraitsWithoutSecureDigitalAreNotEnough() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/ExternalDrive")
        let manager = DiskManager(metadataProvider: FakeDiskMetadataProvider(metadata: DiskVolumeMetadata(
            volumeURL: volumeURL,
            protocolName: "USB",
            isWritable: true,
            isRemovable: true,
            isEjectable: true,
            isInternal: false
        )))

        #expect(manager.readiness(for: volumeURL) == .unavailable(reason: .notSecureDigital))
    }
}

private struct FakeDiskMetadataProvider: DiskMetadataProvider {
    let metadata: DiskVolumeMetadata?

    func metadata(for volumeURL: URL) -> DiskVolumeMetadata? {
        metadata
    }
}
