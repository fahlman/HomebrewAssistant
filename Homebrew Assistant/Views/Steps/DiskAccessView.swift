//
//  DiskAccessView.swift
//  Homebrew Assistant
//
//  Purpose: Presents sandbox-friendly SD card selection and readiness state.
//  Owns: Disk access explanation UI, selected-volume section layout, and selected
//  drive card layout.
//  Does not own: Scoped access lifecycle, SD card picker state, native volume
//  metadata resolution, SD card readiness policy, selected-drive presentation
//  formatting, file writes, workflow navigation, or eject behavior.
//  Uses: SDSelectionController for selection state, DriveSelectionPresentation
//  for selected-drive presentation data, and localized strings for user-facing
//  copy.
//

internal import SwiftUI
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
