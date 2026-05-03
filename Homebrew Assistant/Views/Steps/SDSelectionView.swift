//
//  SDSelectionView.swift
//  Homebrew Assistant
//
//  Purpose: Presents SD card selection and validation state.
//  Owns: Choose SD Card action presentation, SD card validation result
//  presentation, Open Disk Utility affordance presentation, and user-facing
//  explanation of scoped SD card access.
//  Does not own: Scoped access lifecycle, SD card picker presentation state,
//  Disk Arbitration metadata resolution, SD card readiness policy, file writes,
//  or eject behavior.
//  Delegates to: WorkflowCoordinator, SDSelectionController, and SDCardReadiness.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SDSelectionView: View {
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
                .font(.headline)

            Text(String(localized: "sdSelection.accessPrompt.message"))
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var selectedVolumeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "sdSelection.selectedVolume.label"))
                .font(.headline)

            DriveSelectionCard(selectedDrive: controller.selectedDrive)
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
        case .notWritable:
            String(localized: "sdSelection.readiness.notWritable")
        }
    }
}

private struct DriveSelectionCard: View {
    let selectedDrive: SelectedDrive?

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(spacing: 6) {
                Image(nsImage: driveIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)

                Text(displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 128)
            }

            statusView

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var driveIcon: NSImage {
        guard let selectedDrive else {
            return NSWorkspace.shared.icon(for: .volume)
        }

        return NSWorkspace.shared.icon(forFile: selectedDrive.volumeURL.path)
    }

    private var displayName: String {
        selectedDrive?.displayName ?? String(localized: "sdSelection.noValidSDCard.label")
    }

    @ViewBuilder
    private var statusView: some View {
        if let selectedDrive {
            switch selectedDrive.readiness {
            case .ready:
                Label(
                    String(localized: "sdSelection.readiness.readyDrive\(selectedDrive.displayName)"),
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundStyle(AppStatusStyle.success)
            case .unavailable:
                Label(
                    String(localized: "sdSelection.readiness.invalidDrive\(selectedDrive.displayName)"),
                    systemImage: "xmark.circle.fill"
                )
                .foregroundStyle(AppStatusStyle.failure)
            }
        } else {
            Label(String(localized: "sdSelection.readiness.noValidSDCard"), systemImage: "questionmark.circle.fill")
                .foregroundStyle(AppStatusStyle.neutral)
        }
    }
}
