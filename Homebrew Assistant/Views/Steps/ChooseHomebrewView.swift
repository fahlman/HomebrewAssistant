//
//  ChooseHomebrewView.swift
//  Homebrew Assistant
//
//  Purpose: Presents selectable internal workflows and public recipes.
//  Owns: Item catalog layout, selected/unselected presentation, public recipe
//  catalog unavailable/invalid/empty presentation, retry affordance presentation,
//  and trust/source status presentation.
//  Does not own: Public recipe catalog loading, signed index verification,
//  source policy, internal workflow behavior, or recipe preparation.
//  Delegates to: WorkflowCoordinator, RecipeCatalogLoader, and InternalWorkflowCatalog.
//

import SwiftUI

struct ChooseHomebrewView: View {
    @ObservedObject var coordinator: WorkflowCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            internalWorkflowsSection
            publicRecipesSection
        }
    }

    private var internalWorkflowsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "chooseItems.internalWorkflows.sectionTitle"))
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(InternalWorkflowKind.allCases) { kind in
                    Toggle(isOn: binding(for: kind)) {
                        Label(String(localized: String.LocalizationValue(kind.titleKey)), systemImage: kind.systemImageName)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)

                    if kind != InternalWorkflowKind.allCases.last {
                        Divider()
                    }
                }
            }
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var publicRecipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "chooseItems.publicRecipes.sectionTitle"))
                .font(.headline)

            ContentUnavailableView(
                String(localized: "chooseItems.publicRecipes.unavailable.title"),
                systemImage: "network.slash",
                description: Text(String(localized: "chooseItems.publicRecipes.unavailable.description"))
            )
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func binding(for kind: InternalWorkflowKind) -> Binding<Bool> {
        Binding {
            coordinator.selectedInternalWorkflows.contains(kind)
        } set: { isSelected in
            var selectedWorkflows = coordinator.selectedInternalWorkflows

            if isSelected {
                selectedWorkflows.insert(kind)
            } else {
                selectedWorkflows.remove(kind)
            }

            coordinator.updateSelectedInternalWorkflows(selectedWorkflows)
        }
    }
}
