//
//  WorkflowSidebarView.swift
//  Homebrew Assistant
//
//  Purpose: Renders the fixed workflow sidebar.
//  Owns: Sidebar list and row presentation, step icons and labels, status title
//  and symbol-variant mapping, selection affordances, locked-state presentation,
//  and accessibility labels.
//  Does not own: Step ordering decisions, workflow availability rules, workflow
//  advancement, scoped filesystem access, disk operations, or recipe operations.
//  Uses: WorkflowCoordinator for workflow items, selected item binding,
//  reachability, state lookup, and selection; WorkflowItem and StepState for
//  sidebar row metadata.
//

internal import SwiftUI

struct WorkflowSidebarView: View {
    @ObservedObject var coordinator: WorkflowCoordinator

    var body: some View {
        List(selection: selectedItemBinding) {
            ForEach(coordinator.workflowItems) { item in
                WorkflowSidebarRow(
                    item: item,
                    state: coordinator.state(for: item),
                    isReachable: coordinator.canSelect(item)
                )
                .tag(item.id)
                .disabled(!coordinator.canSelect(item))
            }
        }
    }

    private var selectedItemBinding: Binding<WorkflowItem.ID?> {
        Binding(
            get: {
                coordinator.selectedItemID
            },
            set: { selectedItemID in
                guard let selectedItemID,
                      let selectedItem = coordinator.workflowItems.first(where: { $0.id == selectedItemID }) else {
                    return
                }

                DispatchQueue.main.async {
                    coordinator.select(selectedItem)
                }
            }
        )
    }
}

private struct WorkflowSidebarRow: View {
    let item: WorkflowItem
    let state: StepState
    let isReachable: Bool

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: String.LocalizationValue(item.titleKey)))
                    .font(.body)
                
                Text(String(localized: String.LocalizationValue(state.status.titleKey)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: isReachable ? item.systemImageName : "lock.fill")
                .symbolVariant(isReachable ? state.status.symbolVariant : .none)
                .foregroundStyle(isReachable ? .primary : .secondary)
        }
        .foregroundStyle(isReachable ? .primary : .secondary)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let itemTitle = String(localized: String.LocalizationValue(item.titleKey))
        let statusTitle = String(localized: String.LocalizationValue(state.status.titleKey))
        if isReachable {
            return "\(itemTitle), \(statusTitle)"
        }

        return "\(itemTitle), locked, \(statusTitle)"
    }
}

private extension StepStatus {
    var titleKey: String {
        switch self {
        case .unavailable:
            "workflow.stepStatus.unavailable"
        case .notStarted:
            "workflow.stepStatus.notStarted"
        case .inProgress:
            "workflow.stepStatus.inProgress"
        case .completed:
            "workflow.stepStatus.completed"
        case .failed:
            "workflow.stepStatus.failed"
        }
    }

    var symbolVariant: SymbolVariants {
        switch self {
        case .completed:
            .fill
        default:
            .none
        }
    }
}
