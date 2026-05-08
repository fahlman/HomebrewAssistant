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

import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = WorkflowCoordinator()
    @StateObject private var sdSelectionController = SDSelectionController()
    @State private var hasOpenedDiskUtilityForCurrentSelection = false

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
            coordinator.setWorkflowItem(.fixed(.sdCardSelection), isCompleted: isGrantDiskAccessComplete)
        }
    }
    
    private var bottomBarConfiguration: WorkflowBottomBarConfiguration {
        guard case .fixed(.sdCardSelection)? = coordinator.selectedItem else {
            return .automatic
        }

        let contextualActions = diskAccessContextualActions

        return WorkflowBottomBarConfiguration(
            contextualActions: contextualActions,
            defaultAction: diskAccessDefaultAction(for: contextualActions)
        )
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
