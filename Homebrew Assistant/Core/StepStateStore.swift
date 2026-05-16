//
//  StepStateStore.swift
//  Homebrew Assistant
//
//  Purpose: Stores session-only state for fixed workflow/sidebar items.
//  Owns: Workflow step status and optional progress values keyed by workflow
//  item ID.
//  Does not own: Workflow navigation rules, homebrew preparation state, selected
//  homebrew option IDs, diagnostics, recoverable errors, scoped filesystem access,
//  disk operations, downloads, writes, or persistent workflow restoration.
//  Consumed by: WorkflowCoordinator and views/controllers that need fixed-step state.
//

import Foundation

nonisolated struct StepStateStore {
    private var statesByItemID: [WorkflowItem.ID: StepState]

    init(statesByItemID: [WorkflowItem.ID: StepState] = [:]) {
        self.statesByItemID = statesByItemID
    }

    subscript(itemID: WorkflowItem.ID) -> StepState {
        get {
            statesByItemID[itemID, default: .notStarted]
        }
        set {
            statesByItemID[itemID] = newValue
        }
    }

    mutating func reset() {
        statesByItemID.removeAll()
    }

    mutating func removeState(for itemID: WorkflowItem.ID) {
        statesByItemID.removeValue(forKey: itemID)
    }

    mutating func removeStates(except allowedItemIDs: Set<WorkflowItem.ID>) {
        statesByItemID = statesByItemID.filter { itemID, _ in
            allowedItemIDs.contains(itemID)
        }
    }
}

nonisolated struct StepState: Equatable, Sendable {
    var status: StepStatus
    var progress: Double?

    init(
        status: StepStatus,
        progress: Double? = nil
    ) {
        self.status = status
        self.progress = progress
    }

    static let unavailable = StepState(status: .unavailable)
    static let notStarted = StepState(status: .notStarted)
}

nonisolated enum StepStatus: String, CaseIterable, Hashable, Sendable {
    case unavailable
    case notStarted
    case inProgress
    case completed
    case failed
}
