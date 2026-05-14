//
//  DriveSelectionPresentationTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies selected-drive presentation data for the SD card selection UI.
//  Covers: No-selection fallback copy, ready-drive status/recovery copy,
//  metadata row values, unsupported-filesystem recovery copy, and unknown metadata
//  fallbacks.
//  Does not cover: SwiftUI layout, native icon rendering, Disk Arbitration lookup,
//  scoped filesystem access, SD card readiness policy, file writes, or workflow
//  navigation.
//

import Foundation
import Testing
@testable import Homebrew_Assistant

@MainActor
struct DriveSelectionPresentationTests {
    @Test func noSelectedDriveUsesFallbackPresentation() {
        let presentation = DriveSelectionPresentation(selectedDrive: nil)

        #expect(presentation.displayName == String(localized: "sdSelection.noValidSDCard.label"))
        #expect(presentation.statusMessage == String(localized: "sdSelection.readiness.noValidSDCard"))
        #expect(presentation.recoveryMessage == String(localized: "sdSelection.readiness.noValidSDCard.recovery"))
        #expect(presentation.statusIconName == "questionmark.circle.fill")
        #expect(presentation.metadataRows == nil)
    }

    @Test func readyDriveUsesReadyStatusRecoveryAndMetadataRows() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let metadata = DiskVolumeMetadata(
            volumeURL: volumeURL,
            localizedName: "Test SD",
            protocolName: "Secure Digital",
            fileSystemType: "msdos",
            totalCapacityBytes: 32_000_000_000,
            availableCapacityBytes: 16_000_000_000,
            isWritable: true,
            isRemovable: true,
            isEjectable: true,
            isInternal: false
        )
        let selectedDrive = SelectedDrive(volumeURL: volumeURL, readiness: .ready(metadata))
        let presentation = DriveSelectionPresentation(selectedDrive: selectedDrive)

        #expect(presentation.displayName == "Test SD")
        #expect(presentation.statusMessage == String(localized: "sdSelection.readiness.readyDrive\(metadata.displayName)"))
        #expect(presentation.recoveryMessage == String(localized: "sdSelection.readiness.ready.recovery"))
        #expect(presentation.statusIconName == "checkmark.circle.fill")
        #expect(metadataRowValue("media", in: presentation) == "Secure Digital")
        #expect(metadataRowValue("format", in: presentation) == "FAT32")
        #expect(metadataRowValue("freeSpace", in: presentation)?.isEmpty == false)
    }

    @Test func unsupportedFilesystemUsesUnsupportedStatusAndRecoveryCopy() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let metadata = DiskVolumeMetadata(
            volumeURL: volumeURL,
            localizedName: "Test SD",
            protocolName: "Secure Digital",
            fileSystemType: "exfat",
            totalCapacityBytes: nil,
            availableCapacityBytes: nil,
            isWritable: true,
            isRemovable: true,
            isEjectable: true,
            isInternal: false
        )
        let selectedDrive = SelectedDrive(
            volumeURL: volumeURL,
            readiness: .unavailable(reason: .unsupportedFileSystem, metadata: metadata)
        )
        let presentation = DriveSelectionPresentation(selectedDrive: selectedDrive)

        #expect(presentation.displayName == "Test SD")
        #expect(presentation.statusMessage == String(localized: "sdSelection.readiness.unsupportedFileSystem.short"))
        #expect(presentation.recoveryMessage == String(localized: "sdSelection.readiness.unsupportedFileSystem.recovery"))
        #expect(presentation.statusIconName == "xmark.circle.fill")
        #expect(metadataRowValue("format", in: presentation) == "EXFAT")
    }

    @Test func unavailableDriveWithoutMetadataUsesUnknownMetadataFallbacks() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/MysteryDrive")
        let selectedDrive = SelectedDrive(
            volumeURL: volumeURL,
            readiness: .unavailable(reason: .metadataUnavailable, metadata: nil)
        )
        let presentation = DriveSelectionPresentation(selectedDrive: selectedDrive)
        let unknown = String(localized: "sdSelection.metadata.unknown")

        #expect(presentation.displayName == "MysteryDrive")
        #expect(presentation.statusMessage == String(localized: "sdSelection.readiness.metadataUnavailable"))
        #expect(presentation.recoveryMessage == nil)
        #expect(presentation.statusIconName == "xmark.circle.fill")
        #expect(metadataRowValue("media", in: presentation) == unknown)
        #expect(metadataRowValue("format", in: presentation) == unknown)
        #expect(metadataRowValue("freeSpace", in: presentation) == unknown)
    }

    private func metadataRowValue(_ id: String, in presentation: DriveSelectionPresentation) -> String? {
        presentation.metadataRows?.first { row in
            row.id == id
        }?.value
    }
}
