//
//  WorkflowDetailView.swift
//  Homebrew Assistant
//
//  Purpose: Routes the selected workflow item to the correct detail view.
//  Owns: Detail-view routing for fixed workflow steps, internal workflows,
//  public recipe placeholders, and the no-selection placeholder.
//  Does not own: Workflow decisions, service work, recipe parsing, downloads,
//  writing, verification, or file operations.
//  Uses: WorkflowCoordinator, SDSelectionController, and
//  HomebrewDashboardController for state, and routes to DiskAccessView,
//  HomebrewDashboardView, WilbrandView, and RecipeStepView.
//

import SwiftUI

struct WorkflowDetailView: View {
    @ObservedObject var coordinator: WorkflowCoordinator
    @ObservedObject var sdSelectionController: SDSelectionController
    @ObservedObject var homebrewDashboardController: HomebrewDashboardController

    var body: some View {
        ScrollView {
            Group {
                if let selectedItem = coordinator.selectedItem {
                    detailView(for: selectedItem)
                } else {
                    ContentUnavailableView(
                        String(localized: "workflow.detail.noStepSelected.title"),
                        systemImage: "sidebar.left",
                        description: Text(String(localized: "workflow.detail.noStepSelected.description"))
                    )
                }
            }
            .frame(maxWidth: 560, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(55)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func detailView(for item: WorkflowItem) -> some View {
        switch item {
        case .fixed(let fixedStep):
            fixedStepView(for: fixedStep)
        case .internalWorkflow(let kind):
            internalWorkflowView(for: kind)
        case .publicRecipe:
            RecipeStepView()
        }
    }

    @ViewBuilder
    private func fixedStepView(for fixedStep: FixedStep) -> some View {
        switch fixedStep {
        case .sdCardSelection:
            DiskAccessView(controller: sdSelectionController)
        case .chooseItems:
            HomebrewDashboardView(controller: homebrewDashboardController)
        case .reviewSetup, .writeAndVerifyFiles, .success:
            EmptyView()
        }
    }

    @ViewBuilder
    private func internalWorkflowView(for kind: InternalWorkflowKind) -> some View {
        switch kind {
        case .wilbrand:
            WilbrandView()
        case .hackMii:
            RecipeStepView()
        }
    }
}
