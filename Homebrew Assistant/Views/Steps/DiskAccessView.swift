//
//  DiskAccessView.swift
//  Homebrew Assistant
//
//  Purpose: Presents sandbox-friendly SD card selection and readiness state.
//  Owns: Disk access explanation UI, selected-drive card presentation,
//  readiness status/recovery presentation, metadata row presentation,
//  file-system display formatting, capacity display formatting, and selected
//  drive icon/status styling.
//  Does not own: Scoped access lifecycle, SD card picker state, native volume
//  metadata resolution, SD card readiness policy, file writes, workflow
//  navigation, or eject behavior.
//  Uses: SDSelectionController for selection state, SDCardReadiness and
//  DiskVolumeMetadata for readiness/metadata display, AppStatusStyle for status
//  colors, and localized strings for user-facing copy.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct DiskAccessView: View {
    @ObservedObject var controller: SDSelectionController

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            sdAccessSection
            selectedVolumeSection
        }
        .fileImporter(
            isPresented: $controller.isVolumeImporterPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false,
            onCompletion: controller.handleVolumeSelection
        )
        .fileDialogDefaultDirectory(URL(fileURLWithPath: "/Volumes", isDirectory: true))
    }

    private var sdAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "sdSelection.accessPrompt.title"))
                .font(.title2)
                .fontWeight(.semibold)

            Text(String(localized: "sdSelection.accessPrompt.message"))
                .foregroundStyle(.secondary)
                .lineLimit(nil)
        }
    }

    private var selectedVolumeSection: some View {
        let presentation = DriveSelectionPresentation(selectedDrive: controller.selectedDrive)

        return VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "sdSelection.selectedVolume.label"))
                .font(.headline)

            DriveSelectionCard(presentation: presentation)

            VStack(alignment: .leading, spacing: 6) {
                Text(presentation.statusMessage)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(presentation.statusStyle)

                if let recoveryMessage = presentation.recoveryMessage {
                    Text(recoveryMessage)
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(nil)
        }
    }
}

private struct DriveSelectionCard: View {
    let presentation: DriveSelectionPresentation

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(spacing: 6) {
                Image(nsImage: presentation.driveIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                    .overlay(alignment: .bottomTrailing) {
                        statusIcon
                    }

                Text(presentation.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 128)
            }

            metadataView

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var metadataView: some View {
        if let metadataRows = presentation.metadataRows {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(metadataRows) { row in
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(row.title)
                            .fontWeight(.semibold)
                        Text(row.value)
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var statusIcon: some View {
        Image(systemName: presentation.statusIconName)
            .font(.system(size: 32, weight: .semibold))
            .foregroundStyle(presentation.statusStyle)
            .background(.background, in: Circle())
            .accessibilityHidden(true)
    }
}

private struct DriveSelectionPresentation {
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
        case .unavailable(reason: .internalDisk, metadata: _):
            return String(localized: "sdSelection.readiness.internalDisk.recovery")
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
        case .internalDisk:
            String(localized: "sdSelection.readiness.internalDisk")
        case .unsupportedFileSystem:
            String(localized: "sdSelection.readiness.unsupportedFileSystem.short")
        case .notWritable:
            String(localized: "sdSelection.readiness.notWritable")
        }
    }
}
