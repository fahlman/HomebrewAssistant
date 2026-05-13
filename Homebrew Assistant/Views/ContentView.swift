//
//  ContentView.swift
//  Homebrew Assistant
//
//  Purpose: Hosts the app's top-level sidebar/detail window layout and wires
//  shared view-session controllers into the main workflow UI.
//  Owns: NavigationSplitView composition, sidebar/detail/bottom navigation
//  placement, WorkflowCoordinator creation, SDSelectionController creation,
//  HomebrewDashboardController creation, bottom-bar configuration, Disk Utility
//  launch action, and temporary choose-homebrew placeholder phase state.
//  Does not own: SD card validation policy, scoped filesystem access lifecycle,
//  recipe catalog loading, public recipe parsing, downloads, staging, file writes,
//  workflow item rendering, sidebar row rendering, detail-view routing, or bottom
//  button rendering.
//  Uses: WorkflowSidebarView, WorkflowDetailView, BottomNavigationView,
//  WorkflowCoordinator, SDSelectionController, HomebrewDashboardController,
//  WorkflowStepAction, and WorkflowBottomBarConfiguration.
//

import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator: WorkflowCoordinator
    @StateObject private var sdSelectionController = SDSelectionController()
    @StateObject private var homebrewDashboardController: HomebrewDashboardController
    init() {
        let coordinator = WorkflowCoordinator()
        _coordinator = StateObject(wrappedValue: coordinator)
        _homebrewDashboardController = StateObject(
            wrappedValue: HomebrewDashboardController(coordinator: coordinator)
        )
    }
    @State private var hasOpenedDiskUtilityForCurrentSelection = false
    @State private var chooseHomebrewPhase: ChooseHomebrewPhase = .notDownloaded

    var body: some View {
        NavigationSplitView {
            WorkflowSidebarView(coordinator: coordinator)
        } detail: {
            VStack(spacing: 0) {
                WorkflowDetailView(
                    coordinator: coordinator,
                    sdSelectionController: sdSelectionController,
                    homebrewDashboardController: homebrewDashboardController
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
            let contextualActions = chooseHomebrewContextualActions

            return WorkflowBottomBarConfiguration(
                contextualActions: contextualActions,
                canGoForwardOverride: chooseHomebrewCanGoForwardOverride(hasContextualActions: !contextualActions.isEmpty),
                defaultAction: chooseHomebrewDefaultAction(for: contextualActions)
            )
        case nil:
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
                    openWilbrandSetup()
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

    private func chooseHomebrewDefaultAction(for contextualActions: [WorkflowStepAction]) -> WorkflowBottomBarConfiguration.DefaultAction? {
        guard !contextualActions.isEmpty else { return nil }

        return .contextualAction(index: contextualActions.startIndex)
    }

    private func chooseHomebrewCanGoForwardOverride(hasContextualActions: Bool) -> Bool? {
        hasContextualActions ? false : nil
    }

    private var hasSelectedHomebrew: Bool {
        !coordinator.selectedInternalWorkflows.isEmpty
    }

    private var needsWilbrandSetup: Bool {
        coordinator.selectedInternalWorkflows.contains(.wilbrand)
            && chooseHomebrewPhase == .notDownloaded
    }

    private func openWilbrandSetup() {
        chooseHomebrewPhase = .downloaded
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
