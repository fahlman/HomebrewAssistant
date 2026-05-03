//
//  WorkflowDetailView.swift
//  Homebrew Assistant
//
//  Purpose: Routes the selected workflow item to the correct detail view.
//  Owns: Detail-view routing and fixed step, internal workflow, and public recipe
//  presentation selection.
//  Does not own: Workflow decisions, service work, recipe parsing, or file operations.
//  Delegates to: Fixed step views, internal workflow views, RecipeStepView, and WorkflowCoordinator.
//

import SwiftUI

struct WorkflowDetailView: View {
    @ObservedObject var coordinator: WorkflowCoordinator

    var body: some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            SDSelectionView()
        case .chooseItems:
            ChooseItemsView(coordinator: coordinator)
        case .reviewSetup:
            ReviewSetupView()
        case .writeAndVerifyFiles:
            WriteFilesView()
        case .success:
            SuccessView()
        }
    }

    @ViewBuilder
    private func internalWorkflowView(for kind: InternalWorkflowKind) -> some View {
        switch kind {
        case .wilbrand:
            WilbrandView()
        case .hackMii:
            HackMiiView()
        }
    }
}
