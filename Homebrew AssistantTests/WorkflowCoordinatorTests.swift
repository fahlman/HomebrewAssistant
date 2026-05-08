import Testing
@testable import Homebrew_Assistant

@MainActor
struct WorkflowCoordinatorTests {
    @Test func initialWorkflowContainsFixedSteps() {
        let coordinator = WorkflowCoordinator()

        #expect(coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems),
            .fixed(.reviewSetup),
            .fixed(.writeAndVerifyFiles),
            .fixed(.success)
        ])
    }

    @Test func futureStepsAreLockedUntilGrantDiskAccessIsComplete() {
        let coordinator = WorkflowCoordinator()

        #expect(coordinator.canSelect(.fixed(.sdCardSelection)))
        #expect(!coordinator.canSelect(.fixed(.chooseItems)))
        #expect(!coordinator.canSelect(.fixed(.reviewSetup)))
        #expect(!coordinator.canGoForward)
    }

    @Test func completingGrantDiskAccessUnlocksChooseHomebrew() {
        let coordinator = WorkflowCoordinator()

        coordinator.setWorkflowItem(.fixed(.sdCardSelection), isCompleted: true)

        #expect(coordinator.canSelect(.fixed(.chooseItems)))
        #expect(coordinator.canGoForward)
    }

    @Test func selectingLockedFutureStepDoesNothing() {
        let coordinator = WorkflowCoordinator()

        coordinator.select(.fixed(.chooseItems))

        #expect(coordinator.selectedItemID == WorkflowItem.fixed(.sdCardSelection).id)
    }

    @Test func lockingGrantDiskAccessAgainReturnsSelectionToReachableStep() {
        let coordinator = WorkflowCoordinator()

        coordinator.setWorkflowItem(.fixed(.sdCardSelection), isCompleted: true)
        coordinator.select(.fixed(.chooseItems))
        coordinator.setWorkflowItem(.fixed(.sdCardSelection), isCompleted: false)

        #expect(coordinator.selectedItemID == WorkflowItem.fixed(.sdCardSelection).id)
        #expect(!coordinator.canSelect(.fixed(.chooseItems)))
    }

    @Test func chooseHomebrewGatesReviewSetupUntilAnItemIsSelected() {
        let coordinator = WorkflowCoordinator()

        coordinator.setWorkflowItem(.fixed(.sdCardSelection), isCompleted: true)
        coordinator.select(.fixed(.chooseItems))

        #expect(coordinator.canSelect(.fixed(.chooseItems)))
        #expect(!coordinator.canSelect(.fixed(.reviewSetup)))
        #expect(!coordinator.canGoForward)

        coordinator.updateSelectedInternalWorkflows([.hackMii])
        coordinator.setWorkflowItem(.fixed(.chooseItems), isCompleted: true)

        #expect(coordinator.canSelect(.internalWorkflow(.hackMii)))
        #expect(coordinator.canGoForward)
    }

    @Test func visibleInternalWorkflowGatesFollowingSteps() {
        let coordinator = WorkflowCoordinator()
        let hackMiiItem = WorkflowItem.internalWorkflow(.hackMii)

        coordinator.setWorkflowItem(.fixed(.sdCardSelection), isCompleted: true)
        coordinator.updateSelectedInternalWorkflows([.hackMii])
        coordinator.setWorkflowItem(.fixed(.chooseItems), isCompleted: true)
        coordinator.select(hackMiiItem)

        #expect(coordinator.canSelect(hackMiiItem))
        #expect(!coordinator.canSelect(.fixed(.reviewSetup)))
        #expect(!coordinator.canGoForward)

        coordinator.setWorkflowItem(hackMiiItem, isCompleted: true)

        #expect(coordinator.canSelect(.fixed(.reviewSetup)))
        #expect(coordinator.canGoForward)
    }

    @Test func selectingWilbrandInsertsWilbrandBeforeReviewSetup() {
        let coordinator = WorkflowCoordinator()

        coordinator.updateSelectedInternalWorkflows([.wilbrand])

        #expect(coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems),
            .internalWorkflow(.wilbrand),
            .fixed(.reviewSetup),
            .fixed(.writeAndVerifyFiles),
            .fixed(.success)
        ])
    }

    @Test func selectingWilbrandAndHackMiiInsertsInternalWorkflowsInCatalogOrder() {
        let coordinator = WorkflowCoordinator()

        coordinator.updateSelectedInternalWorkflows([.hackMii, .wilbrand])

        #expect(coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems),
            .internalWorkflow(.wilbrand),
            .internalWorkflow(.hackMii),
            .fixed(.reviewSetup),
            .fixed(.writeAndVerifyFiles),
            .fixed(.success)
        ])
    }

    @Test func removingSelectedInternalWorkflowRemovesItFromGeneratedWorkflow() {
        let coordinator = WorkflowCoordinator()

        coordinator.updateSelectedInternalWorkflows([.wilbrand, .hackMii])
        coordinator.updateSelectedInternalWorkflows([.hackMii])

        #expect(coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems),
            .internalWorkflow(.hackMii),
            .fixed(.reviewSetup),
            .fixed(.writeAndVerifyFiles),
            .fixed(.success)
        ])
    }

    @Test func removingSelectedInternalWorkflowDiscardsItsStepState() {
        let coordinator = WorkflowCoordinator()
        let wilbrandItem = WorkflowItem.internalWorkflow(.wilbrand)

        coordinator.updateSelectedInternalWorkflows([.wilbrand])
        coordinator.mark(wilbrandItem, as: StepState(status: .completed))
        coordinator.setWorkflowItem(wilbrandItem, isCompleted: true)
        coordinator.updateSelectedInternalWorkflows([])

        #expect(coordinator.state(for: wilbrandItem).status == .notStarted)
        #expect(!coordinator.isCompleted(wilbrandItem))
    }

    @Test func resetWorkflowReturnsToInitialFixedWorkflow() {
        let coordinator = WorkflowCoordinator()

        coordinator.updateSelectedInternalWorkflows([.wilbrand, .hackMii])
        coordinator.resetWorkflow()

        #expect(coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems),
            .fixed(.reviewSetup),
            .fixed(.writeAndVerifyFiles),
            .fixed(.success)
        ])
        #expect(coordinator.selectedInternalWorkflows.isEmpty)
        #expect(coordinator.selectedPublicRecipes.isEmpty)
        #expect(coordinator.selectedItemID == WorkflowItem.fixed(.sdCardSelection).id)
        #expect(!coordinator.isCompleted(.fixed(.sdCardSelection)))
    }
}
