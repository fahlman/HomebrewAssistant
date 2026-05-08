//
//  ChooseHomebrewView.swift
//  Homebrew Assistant
//
//  Purpose: Presents selectable homebrew options.
//  Owns: Homebrew option filter, sort, card layout, and selected/unselected
//  presentation.
//  Does not own: Homebrew option metadata, public recipe catalog loading,
//  signed index verification, source policy, internal workflow behavior,
//  recipe preparation, downloads, or workflow navigation.
//  Delegates to: WorkflowCoordinator and InternalWorkflowCatalog.
//

import SwiftUI

struct ChooseHomebrewView: View {
    @ObservedObject var coordinator: WorkflowCoordinator
    @State private var selectedCategoryFilter: HomebrewCategoryFilter = .all
    @State private var selectedSortMode: HomebrewSortMode = .category

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "chooseHomebrew.availableHomebrew.sectionTitle"))
                .font(.headline)

            HStack(alignment: .center) {
                Spacer()

                filterMenu
                sortMenu
            }

            VStack(spacing: 12) {
                ForEach(visibleOptions) { option in
                    HomebrewOptionCard(
                        option: option,
                        isSelected: binding(for: option)
                    )
                }
            }
        }
    }

    private var filterMenu: some View {
        Picker(String(localized: "chooseHomebrew.filter.label"), selection: $selectedCategoryFilter) {
            ForEach(HomebrewCategoryFilter.allCases) { filter in
                Text(filter.title)
                    .tag(filter)
            }
        }
        .pickerStyle(.menu)
    }

    private var sortMenu: some View {
        Picker(String(localized: "chooseHomebrew.sort.label"), selection: $selectedSortMode) {
            ForEach(HomebrewSortMode.allCases) { sortMode in
                Text(sortMode.title)
                    .tag(sortMode)
            }
        }
        .pickerStyle(.menu)
    }

    private var visibleOptions: [HomebrewOption] {
        homebrewOptions
            .filter { selectedCategoryFilter.includes($0.category) }
            .sorted(using: selectedSortMode)
    }

    private var homebrewOptions: [HomebrewOption] {
        InternalWorkflowCatalog().homebrewOptions
    }

    private func binding(for option: HomebrewOption) -> Binding<Bool> {
        Binding {
            guard case .internalWorkflow(let kind) = option.source else {
                return false
            }

            return coordinator.selectedInternalWorkflows.contains(kind)
        } set: { isSelected in
            guard case .internalWorkflow(let kind) = option.source else {
                return
            }

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

private struct HomebrewOptionCard: View {
    let option: HomebrewOption
    @Binding var isSelected: Bool

    var body: some View {
        Toggle(isOn: $isSelected) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: option.systemImageName)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(option.name)
                        .font(.headline)

                    Text(option.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}

private enum HomebrewCategoryFilter: CaseIterable, Hashable, Identifiable {
    case all
    case category(HomebrewCategory)

    var id: String {
        switch self {
        case .all:
            "all"
        case .category(let category):
            "category-\(category.rawValue)"
        }
    }

    static var allCases: [HomebrewCategoryFilter] {
        [.all] + HomebrewCategory.allCases.map(HomebrewCategoryFilter.category)
    }

    var title: String {
        switch self {
        case .all:
            String(localized: "chooseHomebrew.category.all")
        case .category(let category):
            category.title
        }
    }

    func includes(_ category: HomebrewCategory) -> Bool {
        switch self {
        case .all:
            true
        case .category(let filteredCategory):
            category == filteredCategory
        }
    }
}

private enum HomebrewSortMode: CaseIterable, Hashable, Identifiable {
    case category
    case alphabetical

    var id: Self { self }

    var title: String {
        switch self {
        case .category:
            String(localized: "chooseHomebrew.sort.category")
        case .alphabetical:
            String(localized: "chooseHomebrew.sort.alphabetical")
        }
    }
}

private extension Array where Element == HomebrewOption {
    func sorted(using sortMode: HomebrewSortMode) -> [HomebrewOption] {
        switch sortMode {
        case .category:
            sorted { lhs, rhs in
                if lhs.category == rhs.category {
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }

                return lhs.category < rhs.category
            }
        case .alphabetical:
            sorted { lhs, rhs in
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
    }
}
