
//
//  WorkflowCoordinator.swift
//  Homebrew Assistant
//
//  Purpose: Coordinates the active workflow session and generated workflow steps.
//  Owns: Current workflow state, selected step, navigation rules, workflow
//  availability decisions, selected internal workflows and public recipes,
//  available actions, high-level workflow transitions, and cleanup requests.
//  Does not own: Scoped filesystem access implementation, disk metadata resolution,
//  recipe catalog loading, public recipe parsing, downloads, archive extraction,
//  staging file management, SD card write execution, verification execution,
//  eject operations, cleanup implementation, or persistent preferences.
//  Delegates to: ScopedAccessManager, DiskManager, RecipeCatalogLoader,
//  InternalWorkflowCatalog, RecipeLoader, ItemPreparationService, DownloadService,
//  StagingManager, SDWriteService, StepStateStore, and AppPreferences.
//

import Foundation
import Combine

final class WorkflowCoordinator: ObservableObject {
    @Published private(set) var workflowItems: [WorkflowItem]
    @Published var selectedItemID: WorkflowItem.ID?
    @Published private(set) var stepStateStore: StepStateStore
    @Published private(set) var selectedInternalWorkflows: Set<InternalWorkflowKind>
    @Published private(set) var selectedPublicRecipes: Set<PublicRecipeWorkflowMetadata>

    private let internalWorkflowCatalog: InternalWorkflowCatalog

    init(
        internalWorkflowCatalog: InternalWorkflowCatalog = InternalWorkflowCatalog(),
        stepStateStore: StepStateStore = StepStateStore()
    ) {
        self.internalWorkflowCatalog = internalWorkflowCatalog
        self.stepStateStore = stepStateStore
        self.selectedInternalWorkflows = []
        self.selectedPublicRecipes = []
        self.workflowItems = Self.initialWorkflowItems()
        self.selectedItemID = workflowItems.first?.id
    }

    var selectedItem: WorkflowItem? {
        guard let selectedItemID else { return nil }

        return workflowItems.first { item in
            item.id == selectedItemID
        }
    }

    var canGoBack: Bool {
        guard let selectedItem else { return false }
        return workflowItems.first != selectedItem
    }

    var canGoForward: Bool {
        guard let selectedItem else { return false }
        return workflowItems.last != selectedItem
    }

    func state(for item: WorkflowItem) -> StepState {
        stepStateStore[item.id]
    }

    func select(_ item: WorkflowItem) {
        guard workflowItems.contains(item) else { return }
        selectedItemID = item.id
    }

    func goBack() {
        guard
            let selectedItem,
            let currentIndex = workflowItems.firstIndex(of: selectedItem),
            currentIndex > workflowItems.startIndex
        else {
            return
        }

        selectedItemID = workflowItems[workflowItems.index(before: currentIndex)].id
    }

    func goForward() {
        guard
            let selectedItem,
            let currentIndex = workflowItems.firstIndex(of: selectedItem),
            currentIndex < workflowItems.index(before: workflowItems.endIndex)
        else {
            return
        }

        selectedItemID = workflowItems[workflowItems.index(after: currentIndex)].id
    }

    func updateSelectedInternalWorkflows(_ selectedWorkflows: Set<InternalWorkflowKind>) {
        selectedInternalWorkflows = selectedWorkflows
        regenerateWorkflowItems()
    }

    func updateSelectedPublicRecipes(_ selectedRecipes: Set<PublicRecipeWorkflowMetadata>) {
        selectedPublicRecipes = selectedRecipes
        regenerateWorkflowItems()
    }

    func mark(_ item: WorkflowItem, as state: StepState) {
        stepStateStore[item.id] = state
    }

    func resetWorkflow() {
        selectedInternalWorkflows.removeAll()
        selectedPublicRecipes.removeAll()
        stepStateStore.reset()
        workflowItems = Self.initialWorkflowItems()
        selectedItemID = workflowItems.first?.id
    }

    private func regenerateWorkflowItems() {
        let previousSelectedItemID = selectedItemID
        let generatedItems = generatedWorkflowItems()
        let allowedItemIDs = Set(generatedItems.map(\.id))

        workflowItems = generatedItems
        stepStateStore.removeStates(except: allowedItemIDs)

        if let previousSelectedItemID, allowedItemIDs.contains(previousSelectedItemID) {
            selectedItemID = previousSelectedItemID
        } else {
            selectedItemID = workflowItems.first?.id
        }
    }

    private func generatedWorkflowItems() -> [WorkflowItem] {
        let leadingItems = Self.leadingFixedItems()

        let internalItems = internalWorkflowCatalog.workflowItems.filter { item in
            guard case .internalWorkflow(let kind) = item else { return false }
            return selectedInternalWorkflows.contains(kind)
        }

        let publicRecipeItems = selectedPublicRecipes
            .sorted { first, second in
                first.sortOrder < second.sortOrder
            }
            .map { recipe in
                WorkflowItem.publicRecipe(recipe)
            }

        let preparationItems = (internalItems + publicRecipeItems).sorted { first, second in
            first.sortOrder < second.sortOrder
        }

        let trailingItems = Self.trailingFixedItems()

        return leadingItems + preparationItems + trailingItems
    }

    private static func initialWorkflowItems() -> [WorkflowItem] {
        leadingFixedItems() + trailingFixedItems()
    }

    private static func leadingFixedItems() -> [WorkflowItem] {
        [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems)
        ]
    }

    private static func trailingFixedItems() -> [WorkflowItem] {
        [
            .fixed(.reviewSetup),
            .fixed(.writeAndVerifyFiles),
            .fixed(.success)
        ]
    }
}
