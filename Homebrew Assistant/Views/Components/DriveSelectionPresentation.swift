//
//  DriveSelectionPresentation.swift
//  Homebrew Assistant
//
//  Purpose: Builds selected-drive presentation data for the SD card selection UI.
//  Owns: Selected-drive display name, icon lookup, readiness status/recovery
//  copy, status styling, metadata rows, filesystem formatting, and capacity
//  formatting.
//  Does not own: SD card selection layout, scoped access lifecycle, native volume
//  metadata lookup, SD card readiness policy, file writes, workflow navigation,
//  or eject behavior.
//  Used by: DiskAccessView and DriveSelectionCard.
//

import AppKit
internal import SwiftUI
import UniformTypeIdentifiers

struct DriveSelectionPresentation {
    struct MetadataRow: Identifiable {
        let id: String
        let title: String
        let value: String
    }

    let selectedDrive: SelectedDrive?

    var displayName: String {
        selectedDrive?.displayName ?? String(localized: "sdSelection.noValidSDCard.label")
    }

    var driveIcon: NSImage {
        guard let selectedDrive else {
            return NSWorkspace.shared.icon(for: .volume)
        }

        return NSWorkspace.shared.icon(forFile: selectedDrive.volumeURL.path)
    }

    var statusMessage: String {
        guard let selectedDrive else {
            return String(localized: "sdSelection.readiness.noValidSDCard")
        }

        switch selectedDrive.readiness {
        case .ready:
            return String(localized: "sdSelection.readiness.readyDrive\(selectedDrive.displayName)")
        case .unavailable(reason: let reason, metadata: _):
            return reason.displayMessage
        }
    }

    var recoveryMessage: String? {
        guard let selectedDrive else {
            return String(localized: "sdSelection.readiness.noValidSDCard.recovery")
        }

        switch selectedDrive.readiness {
        case .ready:
            return String(localized: "sdSelection.readiness.ready.recovery")
        case .unavailable(reason: .notSecureDigital, metadata: _):
            return String(localized: "sdSelection.readiness.notSecureDigital.recovery")
        case .unavailable(reason: .unsupportedFileSystem, metadata: _):
            return String(localized: "sdSelection.readiness.unsupportedFileSystem.recovery")
        case .unavailable:
            return nil
        }
    }

    var statusIconName: String {
        guard let selectedDrive else {
            return "questionmark.circle.fill"
        }

        switch selectedDrive.readiness {
        case .ready:
            return "checkmark.circle.fill"
        case .unavailable:
            return "xmark.circle.fill"
        }
    }

    var statusStyle: Color {
        guard let selectedDrive else {
            return AppStatusStyle.neutralForeground
        }

        switch selectedDrive.readiness {
        case .ready:
            return AppStatusStyle.successForeground
        case .unavailable:
            return AppStatusStyle.failureForeground
        }
    }

    var metadataRows: [MetadataRow]? {
        guard let selectedDrive else {
            return nil
        }

        return [
            MetadataRow(
                id: "media",
                title: String(localized: "sdSelection.metadata.media.label"),
                value: selectedDrive.metadata?.protocolName ?? String(localized: "sdSelection.metadata.unknown")
            ),
            MetadataRow(
                id: "format",
                title: String(localized: "sdSelection.metadata.format.label"),
                value: Self.fileSystemDescription(for: selectedDrive.metadata?.fileSystemType)
            ),
            MetadataRow(
                id: "freeSpace",
                title: String(localized: "sdSelection.metadata.freeSpace.label"),
                value: Self.capacityDescription(
                    availableBytes: selectedDrive.metadata?.availableCapacityBytes,
                    totalBytes: selectedDrive.metadata?.totalCapacityBytes
                )
            )
        ]
    }

    private static func fileSystemDescription(for fileSystemType: String?) -> String {
        guard let fileSystemType else {
            return String(localized: "sdSelection.metadata.unknown")
        }

        switch fileSystemType.lowercased() {
        case "msdos", "fat32", "ms-dos fat32":
            return "FAT32"
        case "exfat":
            return "EXFAT"
        case "apfs":
            return "APFS"
        case "hfs", "hfs+":
            return "Mac OS Extended"
        case "jhfs+":
            return "Mac OS Extended (Journaled)"
        case "hfsx":
            return "Mac OS Extended (Case-sensitive)"
        case "jhfsx":
            return "Mac OS Extended (Case-sensitive, Journaled)"
        case "ntfs":
            return "NTFS"
        default:
            return fileSystemType.uppercased()
        }
    }

    private static func capacityDescription(availableBytes: Int64?, totalBytes: Int64?) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useGB, .useMB]

        switch (availableBytes, totalBytes) {
        case (.some(let availableBytes), .some(let totalBytes)):
            return String(
                localized: "sdSelection.metadata.freeSpace.value\(formatter.string(fromByteCount: availableBytes))\(formatter.string(fromByteCount: totalBytes))"
            )
        case (.some(let availableBytes), .none):
            return formatter.string(fromByteCount: availableBytes)
        case (.none, .some(let totalBytes)):
            return formatter.string(fromByteCount: totalBytes)
        case (.none, .none):
            return String(localized: "sdSelection.metadata.unknown")
        }
    }
}

private extension SelectedDrive {
    var metadata: DiskVolumeMetadata? {
        switch readiness {
        case .ready(let metadata):
            metadata
        case .unavailable(reason: _, metadata: let metadata):
            metadata
        }
    }
}

private extension SDCardReadinessFailureReason {
    var displayMessage: String {
        switch self {
        case .metadataUnavailable:
            String(localized: "sdSelection.readiness.metadataUnavailable")
        case .notSecureDigital:
            String(localized: "sdSelection.readiness.notSecureDigital")
        case .unsupportedFileSystem:
            String(localized: "sdSelection.readiness.unsupportedFileSystem.short")
        case .notWritable:
            String(localized: "sdSelection.readiness.notWritable")
        }
    }
}

