//
//  ContentView.swift
//  Homebrew Assistant
//
//  Purpose: Hosts the app's top-level sidebar/detail window layout.
//  Owns: Main window layout composition, placement of sidebar, detail, and
//  bottom navigation regions, and creation/injection of shared view-session
//  controllers needed by multiple app regions.
//  Does not own: Workflow business logic, disk operations, scoped filesystem access,
//  downloads, staging, or file writes.
//  Delegates to: WorkflowSidebarView, WorkflowDetailView, BottomNavigationView,
//  shared workflow state, and SDSelectionController.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = WorkflowCoordinator()
    @StateObject private var sdSelectionController = SDSelectionController()
    @State private var hasOpenedDiskUtilityForCurrentSelection = false
    @State private var chooseHomebrewPhase: ChooseHomebrewPhase = .notDownloaded

    var body: some View {
        NavigationSplitView {
            WorkflowSidebarView(coordinator: coordinator)
        } detail: {
            VStack(spacing: 0) {
                WorkflowDetailView(
                    coordinator: coordinator,
                    sdSelectionController: sdSelectionController
                )
                BottomNavigationView(
                    coordinator: coordinator,
                    configuration: bottomBarConfiguration
                )
            }
        }
        .frame(minWidth: 720, minHeight: 520)
        .onChange(of: sdSelectionController.readiness) { _, _ in
            hasOpenedDiskUtilityForCurrentSelection = false
            coordinator.invalidateWorkflow(after: .fixed(.sdCardSelection))
            coordinator.setWorkflowItem(.fixed(.sdCardSelection), isCompleted: isGrantDiskAccessComplete)
        }
        .onChange(of: coordinator.selectedInternalWorkflows) { _, _ in
            resetChooseHomebrewProgress()
        }
        .onChange(of: coordinator.selectedPublicRecipes) { _, _ in
            resetChooseHomebrewProgress()
        }
    }

    private var bottomBarConfiguration: WorkflowBottomBarConfiguration {
        switch coordinator.selectedItem {
        case .fixed(.sdCardSelection):
            let contextualActions = diskAccessContextualActions

            return WorkflowBottomBarConfiguration(
                contextualActions: contextualActions,
                defaultAction: diskAccessDefaultAction(for: contextualActions)
            )
        case .fixed(.chooseItems):
            return WorkflowBottomBarConfiguration(
                contextualActions: chooseHomebrewContextualActions,
                defaultAction: nil
            )
        case .internalWorkflow, .publicRecipe, .fixed, nil:
            return .automatic
        }
    }

    private var diskAccessContextualActions: [WorkflowStepAction] {
        var actions: [WorkflowStepAction] = []

        if shouldOfferDiskUtility {
            actions.append(
                WorkflowStepAction(
                    titleKey: "sdSelection.openDiskUtility.button",
                    systemImageName: "externaldrive.badge.gearshape"
                ) {
                    openDiskUtility()
                }
            )
        }

        actions.append(
            WorkflowStepAction(
                titleKey: "sdSelection.chooseSDCard.button",
                systemImageName: "sdcard"
            ) {
                sdSelectionController.presentVolumeImporter()
            }
        )

        return actions
    }

    private func diskAccessDefaultAction(for contextualActions: [WorkflowStepAction]) -> WorkflowBottomBarConfiguration.DefaultAction? {
        if isGrantDiskAccessComplete {
            return .next
        }

        if shouldOfferDiskUtility && !hasOpenedDiskUtilityForCurrentSelection {
            return .contextualAction(index: 0)
        }

        return .contextualAction(index: contextualActions.index(before: contextualActions.endIndex))
    }

    private var chooseHomebrewContextualActions: [WorkflowStepAction] {
        guard hasSelectedHomebrew else { return [] }

        if needsWilbrandSetup {
            return [
                WorkflowStepAction(
                    titleKey: "chooseHomebrew.setupWilbrand.button",
                    systemImageName: "safari"
                ) {
                    coordinator.select(.internalWorkflow(.wilbrand))
                }
            ]
        }

        switch chooseHomebrewPhase {
        case .notDownloaded:
            return [
                WorkflowStepAction(
                    titleKey: "chooseHomebrew.download.button",
                    systemImageName: "arrow.down.circle"
                ) {
                    downloadSelectedHomebrew()
                }
            ]
        case .downloaded:
            return [
                WorkflowStepAction(
                    titleKey: "chooseHomebrew.save.button",
                    systemImageName: "square.and.arrow.down"
                ) {
                    saveSelectedHomebrew()
                }
            ]
        case .saved:
            return []
        }
    }

    private var hasSelectedHomebrew: Bool {
        !coordinator.selectedInternalWorkflows.isEmpty || !coordinator.selectedPublicRecipes.isEmpty
    }

    private var needsWilbrandSetup: Bool {
        coordinator.selectedInternalWorkflows.contains(.wilbrand)
            && !coordinator.isCompleted(.internalWorkflow(.wilbrand))
    }

    private func resetChooseHomebrewProgress() {
        chooseHomebrewPhase = .notDownloaded
    }

    private func downloadSelectedHomebrew() {
        chooseHomebrewPhase = .downloaded
    }

    private func saveSelectedHomebrew() {
        chooseHomebrewPhase = .saved
    }

    private var shouldOfferDiskUtility: Bool {
        guard case .unavailable(reason: .unsupportedFileSystem, metadata: _) = sdSelectionController.readiness else {
            return false
        }

        return true
    }

    private func openDiskUtility() {
        hasOpenedDiskUtilityForCurrentSelection = true
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/Utilities/Disk Utility.app"), configuration: .init())
    }

    private var isGrantDiskAccessComplete: Bool {
        sdSelectionController.readiness?.isReady == true
    }
}

private enum ChooseHomebrewPhase {
    case notDownloaded
    case downloaded
    case saved
}

private extension SDCardReadiness {
    var isReady: Bool {
        if case .ready = self {
            return true
        }

        return false
    }
}

#Preview {
    ContentView()
}
