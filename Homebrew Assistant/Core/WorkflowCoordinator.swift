//
//  WorkflowCoordinator.swift
//  Homebrew Assistant
//
//  Purpose: Coordinates the active workflow session and generated workflow steps.
//  Owns: Current workflow items, selected step, visible-step completion,
//  sequential reachability rules, selected internal workflows and public recipes,
//  high-level workflow transitions, and workflow reset behavior.
//  Does not own: Scoped filesystem access, disk metadata resolution, recipe
//  catalog loading, public recipe parsing, downloads, archive extraction,
//  staging file management, SD card writes, verification execution, eject
//  operations, or persistent preferences.
//  Delegates to: InternalWorkflowCatalog for available internal workflow items
//  and StepStateStore for per-step status storage.
//

import Foundation
import Combine

final class WorkflowCoordinator: ObservableObject {
    @Published private(set) var workflowItems: [WorkflowItem]
    @Published var selectedItemID: WorkflowItem.ID?
    @Published private(set) var stepStateStore: StepStateStore
    @Published private(set) var selectedInternalWorkflows: Set<InternalWorkflowKind>
    @Published private(set) var selectedPublicRecipes: Set<PublicRecipeWorkflowMetadata>
    @Published private(set) var completedWorkflowItemIDs: Set<WorkflowItem.ID>

    private let internalWorkflowCatalog: InternalWorkflowCatalog

    init(
        internalWorkflowCatalog: InternalWorkflowCatalog = InternalWorkflowCatalog(),
        stepStateStore: StepStateStore = StepStateStore()
    ) {
        self.internalWorkflowCatalog = internalWorkflowCatalog
        self.stepStateStore = stepStateStore
        self.selectedInternalWorkflows = []
        self.selectedPublicRecipes = []
        self.completedWorkflowItemIDs = []
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
        return isCompleted(selectedItem)
            && nextItem(after: selectedItem) != nil
            && nextItem(after: selectedItem).map(canSelect) == true
    }

    func state(for item: WorkflowItem) -> StepState {
        stepStateStore[item.id]
    }

    func canSelect(_ item: WorkflowItem) -> Bool {
        guard let itemIndex = workflowItems.firstIndex(of: item) else {
            return false
        }

        return itemIndex <= furthestReachableIndex
    }

    func isCompleted(_ item: WorkflowItem) -> Bool {
        completedWorkflowItemIDs.contains(item.id)
    }

    func select(_ item: WorkflowItem) {
        guard canSelect(item), selectedItemID != item.id else { return }
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

        let previousItemID = workflowItems[workflowItems.index(before: currentIndex)].id
        guard selectedItemID != previousItemID else { return }

        selectedItemID = previousItemID
    }

    func goForward() {
        guard
            let selectedItem,
            let currentIndex = workflowItems.firstIndex(of: selectedItem),
            currentIndex < workflowItems.index(before: workflowItems.endIndex)
        else {
            return
        }
        guard isCompleted(selectedItem) else { return }

        let nextItem = workflowItems[workflowItems.index(after: currentIndex)]
        guard selectedItemID != nextItem.id else { return }

        selectedItemID = nextItem.id
    }

    func updateSelectedInternalWorkflows(_ selectedWorkflows: Set<InternalWorkflowKind>) {
        selectedInternalWorkflows = selectedWorkflows
        regenerateWorkflowItems()
        updateChooseHomebrewCompletion()
    }

    func updateSelectedPublicRecipes(_ selectedRecipes: Set<PublicRecipeWorkflowMetadata>) {
        selectedPublicRecipes = selectedRecipes
        regenerateWorkflowItems()
        updateChooseHomebrewCompletion()
    }

    func setWorkflowItem(_ item: WorkflowItem, isCompleted: Bool) {
        guard workflowItems.contains(item) else { return }

        if isCompleted {
            completedWorkflowItemIDs.insert(item.id)
        } else {
            completedWorkflowItemIDs.remove(item.id)
        }
        stepStateStore[item.id] = StepState(status: isCompleted ? .completed : .notStarted)

        guard let selectedItem, canSelect(selectedItem) else {
            setSelectedItemID(firstSelectableItem?.id)
            return
        }
    }

    private func updateChooseHomebrewCompletion() {
        setWorkflowItem(
            .fixed(.chooseItems),
            isCompleted: !selectedInternalWorkflows.isEmpty || !selectedPublicRecipes.isEmpty
        )
    }

    func mark(_ item: WorkflowItem, as state: StepState) {
        stepStateStore[item.id] = state
    }

    private func setSelectedItemID(_ itemID: WorkflowItem.ID?) {
        guard selectedItemID != itemID else { return }
        selectedItemID = itemID
    }

    func resetWorkflow() {
        selectedInternalWorkflows.removeAll()
        selectedPublicRecipes.removeAll()
        completedWorkflowItemIDs.removeAll()
        stepStateStore.reset()
        workflowItems = Self.initialWorkflowItems()
        setSelectedItemID(workflowItems.first?.id)
    }

    private func regenerateWorkflowItems() {
        let previousSelectedItemID = selectedItemID
        let generatedItems = generatedWorkflowItems()
        let allowedItemIDs = Set(generatedItems.map(\.id))

        workflowItems = generatedItems
        stepStateStore.removeStates(except: allowedItemIDs)
        completedWorkflowItemIDs = completedWorkflowItemIDs.intersection(allowedItemIDs)

        if let previousSelectedItemID,
           allowedItemIDs.contains(previousSelectedItemID),
           let previousSelectedItem = workflowItems.first(where: { $0.id == previousSelectedItemID }),
           canSelect(previousSelectedItem) {
            setSelectedItemID(previousSelectedItemID)
        } else {
            setSelectedItemID(firstSelectableItem?.id)
        }
    }

    private var firstSelectableItem: WorkflowItem? {
        workflowItems.first { item in
            canSelect(item)
        }
    }

    private var furthestReachableIndex: Int {
        guard !workflowItems.isEmpty else { return workflowItems.startIndex }

        for (index, item) in workflowItems.enumerated() {
            if !isCompleted(item) {
                return index
            }
        }

        return workflowItems.index(before: workflowItems.endIndex)
    }

    private func nextItem(after item: WorkflowItem) -> WorkflowItem? {
        guard
            let currentIndex = workflowItems.firstIndex(of: item),
            currentIndex < workflowItems.index(before: workflowItems.endIndex)
        else {
            return nil
        }

        return workflowItems[workflowItems.index(after: currentIndex)]
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
