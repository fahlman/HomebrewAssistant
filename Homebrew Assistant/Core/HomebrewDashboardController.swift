//
//  HomebrewDashboardController.swift
//  Homebrew Assistant
//
//  Purpose: Coordinates the Choose Homebrew dashboard's options, selection,
//  preparation state, and bottom-bar action policy.
//  Owns: Dashboard filter state, sort state, visible option ordering, option
//  selection updates, preparation status storage/mapping, dashboard action state,
//  completion-state notifications, and Choose Homebrew bottom-bar configuration.
//  Does not own: Homebrew option rendering, bottom-bar rendering, recipe
//  loading, download execution, verification, archive extraction, staging,
//  SD card writes, or workflow navigation.
//  Uses: WorkflowCoordinator for selected built-in homebrew state,
//  InternalWorkflowCatalog for built-in homebrew option metadata,
//  HomebrewPreparationStateStore for per-option preparation state, and
//  HomebrewPreparationAction for setup/download/save intents.
//

import Combine
internal import SwiftUI

final class HomebrewDashboardController: ObservableObject {
    @Published var selectedCategoryFilter: HomebrewCategoryFilter = .all
    @Published var selectedSortMode: HomebrewSortMode = .category
    @Published private var preparationStateStore: HomebrewPreparationStateStore

    var onCompletionStateChanged: ((Bool) -> Void)?

    private let coordinator: WorkflowCoordinator
    private let internalWorkflowCatalog: InternalWorkflowCatalog
    private var coordinatorCancellable: AnyCancellable?

    init(
        coordinator: WorkflowCoordinator,
        internalWorkflowCatalog: InternalWorkflowCatalog = InternalWorkflowCatalog(),
        preparationStateStore: HomebrewPreparationStateStore = HomebrewPreparationStateStore()
    ) {
        self.coordinator = coordinator
        self.internalWorkflowCatalog = internalWorkflowCatalog
        self.preparationStateStore = preparationStateStore
        self.coordinatorCancellable = coordinator.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }

    var visibleOptions: [HomebrewOption] {
        availableOptions
            .filter { selectedCategoryFilter.includes($0.category) }
            .sorted(using: selectedSortMode)
    }

    func binding(for option: HomebrewOption) -> Binding<Bool> {
        Binding {
            self.isSelected(option)
        } set: { isSelected in
            self.setOption(option, isSelected: isSelected)
        }
    }

    func status(for option: HomebrewOption) -> HomebrewPreparationStatus {
        guard isSelected(option) else {
            return .notSelected
        }

        let storedStatus = preparationStateStore[option.id]
        guard storedStatus == .notSelected else {
            return storedStatus
        }

        return initialPreparationStatus(for: option)
    }

    var actionState: HomebrewDashboardActionState {
        let selectedOptions = visibleOptions.filter(isSelected)

        guard !selectedOptions.isEmpty else {
            return .nothingSelected
        }

        if selectedOptions.contains(where: { option in
            option.source == .internalWorkflow(.wilbrand)
                && status(for: option) == .setupRequired
        }) {
            return .needsWilbrandSetup
        }

        if selectedOptions.contains(where: { option in
            status(for: option) == .readyToDownload
        }) {
            return .readyToDownload
        }

        if selectedOptions.contains(where: { option in
            status(for: option) == .readyToSave
        }) {
            return .readyToSave
        }

        return .complete
    }

    var bottomBarConfiguration: WorkflowBottomBarConfiguration {
        actionState.bottomBarConfiguration(controller: self)
    }

    func perform(_ action: HomebrewPreparationAction) {
        switch action {
        case .setUpWilbrand:
            markWilbrandSetupHandled()
        case .download:
            markReadyToDownloadOptionsPrepared()
        case .save:
            markReadyToSaveOptionsSaved()
        }

        notifyCompletionStateChanged()
    }

    private func markWilbrandSetupHandled() {
        guard let wilbrandOption = availableOptions.first(where: { option in
            option.source == .internalWorkflow(.wilbrand)
        }), isSelected(wilbrandOption) else {
            return
        }

        preparationStateStore[wilbrandOption.id] = .readyToSave
    }

    private func markReadyToDownloadOptionsPrepared() {
        for option in visibleOptions where isSelected(option) && status(for: option) == .readyToDownload {
            preparationStateStore[option.id] = .readyToSave
        }
    }

    private func markReadyToSaveOptionsSaved() {
        for option in visibleOptions where isSelected(option) && status(for: option) == .readyToSave {
            preparationStateStore[option.id] = .saved
        }
    }

    private var availableOptions: [HomebrewOption] {
        internalWorkflowCatalog.homebrewOptions
    }

    private func isSelected(_ option: HomebrewOption) -> Bool {
        guard case .internalWorkflow(let kind) = option.source else {
            return false
        }

        return coordinator.selectedInternalWorkflows.contains(kind)
    }

    private func setOption(_ option: HomebrewOption, isSelected: Bool) {
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

        if isSelected {
            if preparationStateStore[option.id] == .notSelected {
                preparationStateStore[option.id] = initialPreparationStatus(for: option)
            }
        } else {
            preparationStateStore.removeStatus(for: option.id)
        }

        notifyCompletionStateChanged()
    }

    private func notifyCompletionStateChanged() {
        onCompletionStateChanged?(actionState == .complete)
    }

    private func initialPreparationStatus(for option: HomebrewOption) -> HomebrewPreparationStatus {
        switch option.source {
        case .internalWorkflow(.wilbrand):
            .setupRequired
        case .internalWorkflow(.hackMii):
            .readyToDownload
        case .publicRecipe:
            .readyToDownload
        }
    }
}

enum HomebrewCategoryFilter: CaseIterable, Hashable, Identifiable {
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

enum HomebrewSortMode: CaseIterable, Hashable, Identifiable {
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
