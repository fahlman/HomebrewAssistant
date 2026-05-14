//
//  SDCardValidationServiceTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies SD card readiness classification from injected disk metadata.
//  Covers: Missing metadata, missing protocol name, non-Secure-Digital volumes,
//  read-only Secure Digital volumes, writable Secure Digital volumes, and
//  rejection of removable/ejectable/external
//  non-Secure-Digital volumes.
//  Does not cover: Native Disk Arbitration metadata lookup, scoped filesystem
//  access, UI presentation, workflow navigation, file writes, or physical SD card
//  hardware behavior.
//

import Foundation
import Testing
@testable import Homebrew_Assistant

struct SDCardValidationServiceTests {
    @Test func metadataUnavailableReturnsMetadataUnavailable() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let manager = SDCardValidationService(metadataProvider: MutableDiskMetadataProvider(metadata: nil))

        #expect(manager.readiness(for: volumeURL) == .unavailable(reason: .metadataUnavailable))
    }

    @Test func nilProtocolReturnsNotSecureDigital() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let manager = SDCardValidationService(metadataProvider: MutableDiskMetadataProvider(metadata: DiskVolumeMetadata(
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
        let manager = SDCardValidationService(metadataProvider: MutableDiskMetadataProvider(metadata: DiskVolumeMetadata(
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
        let manager = SDCardValidationService(metadataProvider: MutableDiskMetadataProvider(metadata: DiskVolumeMetadata(
            volumeURL: volumeURL,
            protocolName: "Secure Digital",
            fileSystemType: "msdos",
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
        let metadata = readySecureDigitalMetadata(for: volumeURL)
        let manager = SDCardValidationService(metadataProvider: MutableDiskMetadataProvider(metadata: metadata))

        #expect(manager.readiness(for: volumeURL) == .ready(metadata))
    }

    @Test func internalSecureDigitalMediaCanBeReady() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/InternalSD")
        let metadata = DiskVolumeMetadata(
            volumeURL: volumeURL,
            protocolName: "Secure Digital",
            fileSystemType: "msdos",
            isWritable: true,
            isRemovable: false,
            isEjectable: false,
            isInternal: true
        )
        let manager = SDCardValidationService(metadataProvider: MutableDiskMetadataProvider(metadata: metadata))

        #expect(manager.readiness(for: volumeURL) == .ready(metadata))
    }

    @Test func removableEjectableExternalTraitsWithoutSecureDigitalAreNotEnough() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/ExternalDrive")
        let manager = SDCardValidationService(metadataProvider: MutableDiskMetadataProvider(metadata: DiskVolumeMetadata(
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
