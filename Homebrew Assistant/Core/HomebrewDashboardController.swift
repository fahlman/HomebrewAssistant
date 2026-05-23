//
//  HomebrewDashboardController.swift
//  Homebrew Assistant
//
//  Purpose: Coordinates the Choose Homebrew dashboard's options, selection,
//  preparation state, and bottom-bar action policy.
//  Owns: Dashboard filter state, sort state, visible option ordering,
//  selection updates, selected option derivation, preparation status storage/mapping,
//  preparation transition recording, explicit dashboard action state, explicit
//  completion state, and Choose Homebrew bottom-bar configuration.
//  Does not own: Homebrew option rendering, bottom-bar rendering, recipe
//  loading, download execution, verification, archive extraction, staging,
//  SD card writes, or workflow navigation.
//  Uses: HomebrewOption IDs for dashboard-owned selection state,
//  BuiltInHomebrewCatalog for built-in homebrew option metadata,
//  HomebrewPreparationStateStore for per-option preparation state, and
//  HomebrewPreparationExecutor for setup/download/save execution intents.
//

import Combine
import Foundation

@MainActor
final class HomebrewDashboardController: ObservableObject {
    @Published var selectedCategoryFilter: HomebrewCategoryFilter = .all
    @Published var selectedSortMode: HomebrewSortMode = .category
    @Published private var selectedOptionIDs: Set<HomebrewOption.ID>
    @Published private var preparationStateStore: HomebrewPreparationStateStore
    @Published private(set) var actionState: HomebrewDashboardActionState
    @Published private(set) var preparationTransitions: [HomebrewPreparationStateTransition]

    private let builtInHomebrewCatalog: BuiltInHomebrewCatalog
    private let diagnosticsStore: HomebrewPreparationDiagnosticsStore
    private let preparationExecutor: any HomebrewPreparationExecutor

    init(
        builtInHomebrewCatalog: BuiltInHomebrewCatalog? = nil,
        preparationStateStore: HomebrewPreparationStateStore? = nil,
        selectedOptionIDs: Set<HomebrewOption.ID>? = nil,
        diagnosticsStore: HomebrewPreparationDiagnosticsStore? = nil,
        preparationExecutor: (any HomebrewPreparationExecutor)? = nil
    ) {
        let diagnosticsStore = diagnosticsStore ?? HomebrewPreparationDiagnosticsStore()
        let builtInHomebrewCatalog = builtInHomebrewCatalog ?? BuiltInHomebrewCatalog()

        self.builtInHomebrewCatalog = builtInHomebrewCatalog
        self.preparationStateStore = preparationStateStore
            ?? HomebrewPreparationStateStore()
        self.selectedOptionIDs = selectedOptionIDs
            ?? []
        self.diagnosticsStore = diagnosticsStore
        self.preparationExecutor = preparationExecutor ?? ImmediateHomebrewPreparationExecutor(
            payloadDownloader: URLSessionHomebrewPayloadDownloader(
                diagnosticsRecorder: diagnosticsStore
            ),
            archiveExtractor: ZIPFoundationHomebrewArchiveExtractor(
                diagnosticsRecorder: diagnosticsStore
            ),
            browserOpener: AppKitBrowserOpener(),
            diagnosticsRecorder: diagnosticsStore
        )
        self.actionState = .nothingSelected
        self.preparationTransitions = []
        synchronizeActionState()
    }

    var visibleOptions: [HomebrewOption] {
        availableOptions
            .filter { selectedCategoryFilter.includes($0.category) }
            .sorted(using: selectedSortMode)
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

    func preparedPayloadURL(for option: HomebrewOption) -> URL? {
        preparationStateStore.preparedPayloadURL(for: option.id)
    }

    func extractedPayloadDirectoryURL(for option: HomebrewOption) -> URL? {
        preparationStateStore.extractedPayloadDirectoryURL(for: option.id)
    }

    private var derivedActionState: HomebrewDashboardActionState {
        let selectedPreparationStates = selectedPreparationStates

        guard !selectedPreparationStates.isEmpty else {
            return .nothingSelected
        }

        if selectedPreparationStates.containsDownloading {
            return .downloading
        }

        if selectedPreparationStates.contains(.extracting) {
            return .extracting
        }

        if selectedPreparationStates.containsSaving {
            return .saving
        }

        let setupRequiredOptions = selectedPreparationStates.options(matching: .setupRequired)
        if setupRequiredOptions.count == 1 {
            return .needsSetup(optionName: setupRequiredOptions[0].name)
        }
        if setupRequiredOptions.count > 1 {
            return .needsSetup(optionName: nil)
        }

        if selectedPreparationStates.contains(.generatedArchiveRequired) {
            return .needsGeneratedArchiveFile
        }

        if selectedPreparationStates.contains(.readyToDownload) {
            return .readyToDownload
        }

        if selectedPreparationStates.contains(.readyToExtract) {
            return .readyToExtract
        }

        if selectedPreparationStates.containsAny(of: [.readyToSave, .downloaded]) {
            return .readyToSave
        }

        if selectedPreparationStates.containsFailure {
            return .failed
        }

        return .complete
    }

    var bottomBarConfiguration: WorkflowBottomBarConfiguration {
        actionState.bottomBarConfiguration(controller: self)
    }

    var preparationDiagnostics: [HomebrewPreparationDiagnosticEvent] {
        diagnosticsStore.events
    }

    func bottomBarConfiguration(for actionState: HomebrewDashboardActionState) -> WorkflowBottomBarConfiguration {
        actionState.bottomBarConfiguration(controller: self)
    }

    func reconcilePreparedState(using reconciler: any HomebrewPreparationStateReconciling) {
        let reconciledState = reconciler.reconciledState(for: availableOptions)
        let reconciledOptionIDs = reconciledState.selectedOptionIDs
        applyCleanupActions(reconciledState.cleanupActions)

        for option in availableOptions where reconciledOptionIDs.contains(option.id) {
            selectedOptionIDs.insert(option.id)
            setPreparationStatus(
                reconciledState.preparationStateStore[option.id],
                for: option,
                reason: .reconciled
            )

            if let preparedPayloadURL = reconciledState.preparationStateStore.preparedPayloadURL(for: option.id) {
                preparationStateStore.setPreparedPayloadURL(
                    preparedPayloadURL,
                    for: option.id
                )
            }
            if let extractedPayloadDirectoryURL = reconciledState.preparationStateStore.extractedPayloadDirectoryURL(for: option.id) {
                preparationStateStore.setExtractedPayloadDirectoryURL(
                    extractedPayloadDirectoryURL,
                    for: option.id
                )
            }
        }

        resetMissingPreparedState(reconciledOptionIDs: reconciledOptionIDs)
        synchronizeActionState()
    }

    private func applyCleanupActions(_ cleanupActions: [HomebrewPreparationCleanupAction]) {
        for cleanupAction in cleanupActions {
            cleanupAction.apply()
        }
    }

    private func resetMissingPreparedState(reconciledOptionIDs: Set<HomebrewOption.ID>) {
        for option in selectedOptions where !reconciledOptionIDs.contains(option.id) {
            let previousStatus = status(for: option)
            guard previousStatus.requiresPreparedPayload else {
                continue
            }

            preparationStateStore.removeStatus(for: option.id)
            let fallbackStatus = fallbackStatusAfterMissingPreparedPayload(for: option)
            preparationStateStore[option.id] = fallbackStatus
            recordPreparationTransition(
                for: option,
                from: previousStatus,
                to: fallbackStatus,
                reason: .reconciled
            )
        }
    }

    private func fallbackStatusAfterMissingPreparedPayload(for option: HomebrewOption) -> HomebrewPreparationStatus {
        switch option.preparationKind {
        case .setupRequired:
            .setupRequired
        case .downloadable:
            preparationStateStore.preparedPayloadURL(for: option.id) == nil
                ? .readyToDownload
                : .readyToExtract
        }
    }

    func perform(_ action: HomebrewPreparationAction) async {
        if let busyActionState = action.busyActionState {
            actionState = busyActionState
        }

        let selectedOptions = selectedOptions
        let updates = preparationExecutor.updates(
            action,
            for: selectedOptions,
            currentStatus: status(for:),
            preparedPayloadURL: preparedPayloadURL(for:)
        )

        for await update in updates {
            apply(update, to: selectedOptions)
            synchronizeActionState()
        }

        synchronizeActionState()
    }

    private func apply(
        _ update: HomebrewPreparationStatusUpdate,
        to selectedOptions: [HomebrewOption]
    ) {
        guard let option = selectedOptions.first(where: { $0.id == update.optionID }) else {
            return
        }

        setPreparationStatus(
            update.newStatus,
            for: option,
            reason: update.reason
        )
        if let preparedPayloadURL = update.preparedPayloadURL {
            preparationStateStore.setPreparedPayloadURL(
                preparedPayloadURL,
                for: option.id
            )
        }
        if let extractedPayloadDirectoryURL = update.extractedPayloadDirectoryURL {
            preparationStateStore.setExtractedPayloadDirectoryURL(
                extractedPayloadDirectoryURL,
                for: option.id
            )
        }
    }

    private var selectedOptions: [HomebrewOption] {
        availableOptions.filter(isSelected)
    }

    private var selectedPreparationStates: [SelectedHomebrewPreparationState] {
        selectedOptions.map { option in
            SelectedHomebrewPreparationState(
                option: option,
                status: status(for: option)
            )
        }
    }

    private var availableOptions: [HomebrewOption] {
        builtInHomebrewCatalog.homebrewOptions
    }

    func isSelected(_ option: HomebrewOption) -> Bool {
        selectedOptionIDs.contains(option.id)
    }

    func setOption(_ option: HomebrewOption, isSelected: Bool) {
        if isSelected {
            guard !selectedOptionIDs.contains(option.id) else { return }

            selectedOptionIDs.insert(option.id)

            let storedStatus = preparationStateStore[option.id]
            let selectedStatus = storedStatus == .notSelected
                ? initialPreparationStatus(for: option)
                : storedStatus

            if storedStatus == .notSelected {
                preparationStateStore[option.id] = selectedStatus
            }

            recordPreparationTransition(
                for: option,
                from: .notSelected,
                to: selectedStatus,
                reason: .selected
            )
        } else {
            guard selectedOptionIDs.contains(option.id) else { return }

            clearPreparationStatus(for: option, reason: .deselected)
            selectedOptionIDs.remove(option.id)
        }

        synchronizeActionState()
    }

    private func setPreparationStatus(
        _ newStatus: HomebrewPreparationStatus,
        for option: HomebrewOption,
        reason: HomebrewPreparationStateTransitionReason
    ) {
        let previousStatus = status(for: option)
        guard previousStatus != newStatus else { return }

        preparationStateStore[option.id] = newStatus
        recordPreparationTransition(
            for: option,
            from: previousStatus,
            to: newStatus,
            reason: reason
        )
    }

    private func clearPreparationStatus(
        for option: HomebrewOption,
        reason: HomebrewPreparationStateTransitionReason
    ) {
        let previousStatus = status(for: option)

        preparationStateStore.removeStatus(for: option.id)
        recordPreparationTransition(
            for: option,
            from: previousStatus,
            to: .notSelected,
            reason: reason
        )
    }

    private func recordPreparationTransition(
        for option: HomebrewOption,
        from previousStatus: HomebrewPreparationStatus,
        to newStatus: HomebrewPreparationStatus,
        reason: HomebrewPreparationStateTransitionReason
    ) {
        guard previousStatus != newStatus else { return }

        preparationTransitions.append(
            HomebrewPreparationStateTransition(
                optionID: option.id,
                optionName: option.name,
                previousStatus: previousStatus,
                newStatus: newStatus,
                reason: reason
            )
        )
    }

    private func synchronizeActionState() {
        let actionState = derivedActionState

        if self.actionState != actionState {
            self.actionState = actionState
        }
    }

    private func initialPreparationStatus(for option: HomebrewOption) -> HomebrewPreparationStatus {
        switch option.preparationKind {
        case .setupRequired:
            .setupRequired
        case .downloadable:
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

private struct SelectedHomebrewPreparationState {
    let option: HomebrewOption
    let status: HomebrewPreparationStatus
}

private extension Array where Element == SelectedHomebrewPreparationState {
    var containsFailure: Bool {
        contains { state in
            if case .failed = state.status {
                return true
            }

            return false
        }
    }

    var containsDownloading: Bool {
        contains { state in
            if case .downloading = state.status {
                return true
            }

            return false
        }
    }

    var containsSaving: Bool {
        contains { state in
            if case .saving = state.status {
                return true
            }

            return false
        }
    }

    func contains(_ status: HomebrewPreparationStatus) -> Bool {
        contains { state in
            state.status == status
        }
    }

    func containsAny(of statuses: [HomebrewPreparationStatus]) -> Bool {
        contains { state in
            statuses.contains(state.status)
        }
    }

    func options(matching status: HomebrewPreparationStatus) -> [HomebrewOption] {
        compactMap { state in
            state.status == status ? state.option : nil
        }
    }
}

    private extension HomebrewPreparationStatus {
    var requiresPreparedPayload: Bool {
        switch self {
        case .downloaded, .readyToExtract, .generatedArchiveRequired, .readyToSave:
            true
        case .notSelected, .setupRequired, .readyToDownload, .downloading, .extracting, .saving, .saved, .failed:
            false
        }
    }
}

private extension HomebrewPreparationAction {
    var busyActionState: HomebrewDashboardActionState? {
        switch self {
        case .download:
            .downloading
        case .extract:
            .extracting
        case .save:
            .saving
        case .setUp, .chooseGeneratedArchive:
            nil
        }
    }
}
