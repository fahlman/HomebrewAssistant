//
//  HomebrewDashboardController.swift
//  Homebrew Assistant
//
//  Purpose: Coordinates the Choose Homebrew dashboard's options, selection,
//  preparation state, and bottom-bar action policy.
//  Owns: Dashboard filter state, sort state, visible option ordering,
//  selection updates, selected option derivation, preparation status storage/mapping,
//  explicit dashboard action state, explicit completion state, and Choose
//  Homebrew bottom-bar configuration.
//  Does not own: Homebrew option rendering, bottom-bar rendering, recipe
//  loading, download execution, verification, archive extraction, staging,
//  SD card writes, or workflow navigation.
//  Uses: HomebrewOption IDs for dashboard-owned selection state,
//  BuiltInHomebrewCatalog for built-in homebrew option metadata,
//  HomebrewPreparationStateStore for per-option preparation state, and
//  HomebrewPreparationAction for setup/download/save intents.
//

internal import SwiftUI
import Combine

final class HomebrewDashboardController: ObservableObject {
    @Published var selectedCategoryFilter: HomebrewCategoryFilter = .all
    @Published var selectedSortMode: HomebrewSortMode = .category
    @Published private var selectedOptionIDs: Set<HomebrewOption.ID>
    @Published private var preparationStateStore: HomebrewPreparationStateStore
    @Published private(set) var actionState: HomebrewDashboardActionState

    @Published private(set) var isComplete: Bool

    private let builtInHomebrewCatalog: BuiltInHomebrewCatalog

    init(
        builtInHomebrewCatalog: BuiltInHomebrewCatalog = BuiltInHomebrewCatalog(),
        preparationStateStore: HomebrewPreparationStateStore = HomebrewPreparationStateStore(),
        selectedOptionIDs: Set<HomebrewOption.ID> = []
    ) {
        self.builtInHomebrewCatalog = builtInHomebrewCatalog
        self.preparationStateStore = preparationStateStore
        self.selectedOptionIDs = selectedOptionIDs
        self.actionState = .nothingSelected
        self.isComplete = false
        synchronizeActionState()
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

    private var derivedActionState: HomebrewDashboardActionState {
        let selectedOptions = selectedOptions

        guard !selectedOptions.isEmpty else {
            return .nothingSelected
        }

        if selectedOptions.contains(where: { option in
            option.source == .builtIn(.wilbrand)
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

        synchronizeActionState()
    }

    private func markWilbrandSetupHandled() {
        guard let wilbrandOption = availableOptions.first(where: { option in
            option.source == .builtIn(.wilbrand)
        }), isSelected(wilbrandOption) else {
            return
        }

        preparationStateStore[wilbrandOption.id] = .readyToSave
    }

    private func markReadyToDownloadOptionsPrepared() {
        for option in selectedOptions where status(for: option) == .readyToDownload {
            preparationStateStore[option.id] = .readyToSave
        }
    }

    private func markReadyToSaveOptionsSaved() {
        for option in selectedOptions where status(for: option) == .readyToSave {
            preparationStateStore[option.id] = .saved
        }
    }

    private var selectedOptions: [HomebrewOption] {
        availableOptions.filter(isSelected)
    }

    private var availableOptions: [HomebrewOption] {
        builtInHomebrewCatalog.homebrewOptions
    }

    private func isSelected(_ option: HomebrewOption) -> Bool {
        selectedOptionIDs.contains(option.id)
    }

    private func setOption(_ option: HomebrewOption, isSelected: Bool) {
        if isSelected {
            selectedOptionIDs.insert(option.id)

            if preparationStateStore[option.id] == .notSelected {
                preparationStateStore[option.id] = initialPreparationStatus(for: option)
            }
        } else {
            selectedOptionIDs.remove(option.id)
            preparationStateStore.removeStatus(for: option.id)
        }

        synchronizeActionState()
    }

    private func synchronizeActionState() {
        let actionState = derivedActionState
        let isComplete = actionState == .complete

        if self.actionState != actionState {
            self.actionState = actionState
        }

        if self.isComplete != isComplete {
            self.isComplete = isComplete
        }
    }

    private func initialPreparationStatus(for option: HomebrewOption) -> HomebrewPreparationStatus {
        switch option.source {
        case .builtIn(.wilbrand):
            .setupRequired
        case .builtIn(.hackMii):
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
