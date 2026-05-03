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

        let readiness = manager.readiness(for: volumeURL)
        guard case .unavailable(reason: .notSecureDigital, metadata: let metadata) = readiness else {
            Issue.record("Expected notSecureDigital readiness, got \(readiness)")
            return
        }

        #expect(metadata?.volumeURL == volumeURL)
        #expect(metadata?.displayName == "TestSD")
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

        let readiness = manager.readiness(for: volumeURL)
        guard case .unavailable(reason: .notSecureDigital, metadata: let metadata) = readiness else {
            Issue.record("Expected notSecureDigital readiness, got \(readiness)")
            return
        }

        #expect(metadata?.volumeURL == volumeURL)
        #expect(metadata?.displayName == "USBDrive")
        #expect(metadata?.protocolName == "USB")
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

        let readiness = manager.readiness(for: volumeURL)
        guard case .unavailable(reason: .notWritable, metadata: let metadata) = readiness else {
            Issue.record("Expected notWritable readiness, got \(readiness)")
            return
        }

        #expect(metadata?.volumeURL == volumeURL)
        #expect(metadata?.displayName == "TestSD")
        #expect(metadata?.protocolName == "Secure Digital")
        #expect(metadata?.isWritable == false)
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

        let readiness = manager.readiness(for: volumeURL)
        guard case .unavailable(reason: .notSecureDigital, metadata: let metadata) = readiness else {
            Issue.record("Expected notSecureDigital readiness, got \(readiness)")
            return
        }

        #expect(metadata?.volumeURL == volumeURL)
        #expect(metadata?.displayName == "ExternalDrive")
        #expect(metadata?.protocolName == "USB")
        #expect(metadata?.isRemovable == true)
        #expect(metadata?.isEjectable == true)
        #expect(metadata?.isInternal == false)
    }
}

private struct FakeDiskMetadataProvider: DiskMetadataProvider {
    let metadata: DiskVolumeMetadata?

    func metadata(for volumeURL: URL) -> DiskVolumeMetadata? {
        metadata
    }
}
