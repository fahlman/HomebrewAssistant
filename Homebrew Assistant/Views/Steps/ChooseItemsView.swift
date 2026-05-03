//
//  ChooseItemsView.swift
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

struct ChooseItemsView: View {
    @ObservedObject var coordinator: WorkflowCoordinator

    var body: some View {
        Form {
            Section(String(localized: "chooseItems.internalWorkflows.sectionTitle")) {
                ForEach(InternalWorkflowKind.allCases) { kind in
                    Toggle(isOn: binding(for: kind)) {
                        Label(String(localized: String.LocalizationValue(kind.titleKey)), systemImage: kind.systemImageName)
                    }
                }
            }

            Section(String(localized: "chooseItems.publicRecipes.sectionTitle")) {
                ContentUnavailableView(
                    String(localized: "chooseItems.publicRecipes.unavailable.title"),
                    systemImage: "network.slash",
                    description: Text(String(localized: "chooseItems.publicRecipes.unavailable.description"))
                )
            }
        }
        .formStyle(.grouped)
        .padding()
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
