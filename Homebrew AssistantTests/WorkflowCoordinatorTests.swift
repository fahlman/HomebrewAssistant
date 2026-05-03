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
        coordinator.updateSelectedInternalWorkflows([])

        #expect(coordinator.state(for: wilbrandItem).status == .notStarted)
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
    }
}
