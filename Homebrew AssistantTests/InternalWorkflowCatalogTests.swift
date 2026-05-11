//
//  InternalWorkflowCatalogTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies the app-owned internal workflow catalog metadata.
//  Covers: Wilbrand and HackMii catalog entries, catalog ordering, generated
//  homebrew options, and workflow definition metadata passthrough.
//  Does not cover: Workflow execution, preparation behavior, downloads, archive
//  extraction, staging, SD card writes, or view rendering.
//

import Testing
@testable import Homebrew_Assistant

@MainActor
struct InternalWorkflowCatalogTests {
    @Test func catalogContainsWilbrandAndHackMiiInSortOrder() {
        let catalog = InternalWorkflowCatalog()

        let sortedKinds = catalog.workflows
            .sorted { $0.sortOrder < $1.sortOrder }

        #expect(sortedKinds == [.wilbrand, .hackMii])
    }

    @Test func homebrewOptionsAreGeneratedFromInternalWorkflowKinds() {
        let catalog = InternalWorkflowCatalog()

        #expect(catalog.homebrewOptions.map(\.source) == [
            .internalWorkflow(.wilbrand),
            .internalWorkflow(.hackMii)
        ])
        #expect(catalog.homebrewOptions.map(\.id) == [
            InternalWorkflowKind.wilbrand.id,
            InternalWorkflowKind.hackMii.id
        ])
        #expect(catalog.homebrewOptions.map(\.name) == [
            "Wilbrand",
            "HackMii"
        ])
    }

    @Test func wilbrandWorkflowExposesKindMetadata() {
        let workflow = WilbrandWorkflow()

        #expect(workflow.kind == .wilbrand)
        #expect(workflow.titleKey == InternalWorkflowKind.wilbrand.titleKey)
        #expect(workflow.summaryKey == InternalWorkflowKind.wilbrand.summaryKey)
        #expect(workflow.category == InternalWorkflowKind.wilbrand.category)
        #expect(workflow.systemImageName == InternalWorkflowKind.wilbrand.systemImageName)
        #expect(workflow.sortOrder == InternalWorkflowKind.wilbrand.sortOrder)
    }

    @Test func hackMiiWorkflowExposesKindMetadata() {
        let workflow = HackMiiWorkflow()

        #expect(workflow.kind == .hackMii)
        #expect(workflow.titleKey == InternalWorkflowKind.hackMii.titleKey)
        #expect(workflow.summaryKey == InternalWorkflowKind.hackMii.summaryKey)
        #expect(workflow.category == InternalWorkflowKind.hackMii.category)
        #expect(workflow.systemImageName == InternalWorkflowKind.hackMii.systemImageName)
        #expect(workflow.sortOrder == InternalWorkflowKind.hackMii.sortOrder)
    }
}
