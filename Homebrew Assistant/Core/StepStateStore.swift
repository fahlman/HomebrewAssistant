//
//  StepStateStore.swift
//  Homebrew Assistant
//
//  Purpose: Stores per-workflow-item session state for the active workflow.
//  Owns: Step status, progress values, selected option IDs, diagnostic messages,
//  recoverable error messages, and session-only step state.
//  Does not own: Workflow navigation rules, scoped filesystem access, disk operations,
//  downloads, writes, diagnostics recording, or persistent workflow restoration.
//  Consumed by: WorkflowCoordinator and views/controllers that need step state.
//

import Foundation

struct StepStateStore {
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

struct StepState: Equatable {
    var status: StepStatus
    var progress: Double?
    var selectedOptionIDs: Set<String>
    var diagnosticMessages: [String]
    var recoverableErrorMessage: String?

    init(
        status: StepStatus,
        progress: Double? = nil,
        selectedOptionIDs: Set<String> = [],
        diagnosticMessages: [String] = [],
        recoverableErrorMessage: String? = nil
    ) {
        self.status = status
        self.progress = progress
        self.selectedOptionIDs = selectedOptionIDs
        self.diagnosticMessages = diagnosticMessages
        self.recoverableErrorMessage = recoverableErrorMessage
    }

    static let unavailable = StepState(status: .unavailable)
    static let notStarted = StepState(status: .notStarted)
}

enum StepStatus: String, CaseIterable, Hashable {
    case unavailable
    case notStarted
    case inProgress
    case preparing
    case prepared
    case completed
    case failed
}
