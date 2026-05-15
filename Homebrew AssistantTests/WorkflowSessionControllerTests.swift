//
//  WorkflowSessionControllerTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies active workflow session controller wiring.
//  Covers: Session controller construction, selected-step bottom-bar state
//  snapshots, synchronization from SD card readiness into fixed workflow-step
//  completion state, and synchronization from Choose Homebrew dashboard
//  completion into fixed workflow-step completion state.
//  Does not cover: SwiftUI layout, sidebar rendering, native button rendering,
//  native scoped access, native disk metadata lookup, downloads, staging, or
//  file writes.
//

import Foundation
internal import SwiftUI
import Testing
@testable import Homebrew_Assistant

@MainActor
struct WorkflowSessionControllerTests {
    @Test func sessionCreatesSharedControllers() {
        let sessionController = WorkflowSessionController()

        #expect(sessionController.coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems)
        ])
        #expect(sessionController.sdSelectionController.readiness == nil)
        #expect(sessionController.homebrewDashboardController.visibleOptions.map(\.source) == [
            .builtIn(.wilbrand),
            .builtIn(.hackMii)
        ])
    }

    @Test func readySDCardSelectionCompletesFixedSDCardStep() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: readySecureDigitalMetadata(for: volumeURL))

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))

        #expect(sessionController.coordinator.isCompleted(.fixed(.sdCardSelection)))
        #expect(sessionController.coordinator.canSelect(.fixed(.chooseItems)))
    }

    @Test func readySDCardSelectionMakesNextTheDefaultBottomBarAction() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: readySecureDigitalMetadata(for: volumeURL))

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))

        #expect(sessionController.bottomBarState.canGoForward)
        #expect(sessionController.bottomBarState.configuration.defaultAction == .next)
    }

    @Test func unavailableSDCardSelectionDoesNotCompleteFixedSDCardStep() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: unsupportedFilesystemSecureDigitalMetadata(for: volumeURL))

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))

        #expect(!sessionController.coordinator.isCompleted(.fixed(.sdCardSelection)))
        #expect(!sessionController.coordinator.canSelect(.fixed(.chooseItems)))
    }

    @Test func unavailableSDCardSelectionKeepsChooseSDCardAsDefaultBottomBarAction() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: unsupportedFilesystemSecureDigitalMetadata(for: volumeURL))

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))

        #expect(!sessionController.bottomBarState.canGoForward)
        #expect(sessionController.bottomBarState.configuration.defaultAction == .contextualAction(index: 0))
    }

    @Test func changingFromReadyToUnavailableInvalidatesFixedSDCardStep() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let metadataProvider = MutableDiskMetadataProvider(metadata: readySecureDigitalMetadata(for: volumeURL))
        let sessionController = makeSessionController(metadataProvider: metadataProvider)

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        #expect(sessionController.coordinator.isCompleted(.fixed(.sdCardSelection)))

        metadataProvider.metadata = unsupportedFilesystemSecureDigitalMetadata(for: volumeURL)
        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))

        #expect(!sessionController.coordinator.isCompleted(.fixed(.sdCardSelection)))
        #expect(sessionController.coordinator.selectedItemID == WorkflowItem.fixed(.sdCardSelection).id)
    }

    @Test func movingToChooseHomebrewRefreshesBottomBarState() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: readySecureDigitalMetadata(for: volumeURL))

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        sessionController.goForward()

        #expect(sessionController.coordinator.selectedItem == .fixed(.chooseItems))
        #expect(sessionController.bottomBarState.canGoBack)
        #expect(!sessionController.bottomBarState.canGoForward)
        #expect(sessionController.bottomBarState.configuration.contextualActions.isEmpty)
        #expect(sessionController.bottomBarState.configuration.defaultAction == nil)
    }

    @Test func selectingHomebrewDoesNotCompleteChooseHomebrewStep() {
        let sessionController = WorkflowSessionController()
        let hackMiiOption = sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        sessionController.homebrewDashboardController.binding(for: hackMiiOption).wrappedValue = true

        #expect(!sessionController.coordinator.isCompleted(.fixed(.chooseItems)))
    }

    @Test func selectingSetupRequiredHomebrewMakesNamedSetupTheDefaultBottomBarAction() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: readySecureDigitalMetadata(for: volumeURL))
        let wilbrandOption = sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.wilbrand)
        }

        #expect(wilbrandOption != nil)
        guard let wilbrandOption else { return }

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        sessionController.goForward()
        sessionController.homebrewDashboardController.binding(for: wilbrandOption).wrappedValue = true

        #expect(sessionController.bottomBarState.canGoBack)
        #expect(!sessionController.bottomBarState.canGoForward)
        #expect(sessionController.bottomBarState.configuration.contextualActions.map(\.titleKey) == [
            HomebrewPreparationAction.setUp(optionName: "Wilbrand").titleKey
        ])
        #expect(sessionController.bottomBarState.configuration.contextualActions.map(\.titleArguments) == [
            HomebrewPreparationAction.setUp(optionName: "Wilbrand").titleArguments
        ])
        #expect(sessionController.bottomBarState.configuration.defaultAction == .contextualAction(index: 0))
    }

    @Test func completingSelectedHomebrewCompletesChooseHomebrewStep() {
        let sessionController = WorkflowSessionController()
        let hackMiiOption = sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        sessionController.homebrewDashboardController.binding(for: hackMiiOption).wrappedValue = true
        sessionController.homebrewDashboardController.perform(.download)
        sessionController.homebrewDashboardController.perform(.save)

        #expect(sessionController.homebrewDashboardController.actionState == .complete)
        #expect(sessionController.coordinator.isCompleted(.fixed(.chooseItems)))
    }

    @Test func completedSelectedHomebrewClearsDashboardBottomBarActions() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: readySecureDigitalMetadata(for: volumeURL))
        let hackMiiOption = sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.hackMii)
        }

        #expect(hackMiiOption != nil)
        guard let hackMiiOption else { return }

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        sessionController.goForward()
        sessionController.homebrewDashboardController.binding(for: hackMiiOption).wrappedValue = true
        sessionController.homebrewDashboardController.perform(.download)
        sessionController.homebrewDashboardController.perform(.save)

        #expect(!sessionController.bottomBarState.canGoForward)
        #expect(sessionController.bottomBarState.configuration.contextualActions.isEmpty)
        #expect(sessionController.bottomBarState.configuration.defaultAction == nil)
    }

    @Test func changingCompletedHomebrewSelectionInvalidatesChooseHomebrewStep() {
        let sessionController = WorkflowSessionController()
        let hackMiiOption = sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.hackMii)
        }
        let wilbrandOption = sessionController.homebrewDashboardController.visibleOptions.first { option in
            option.source == .builtIn(.wilbrand)
        }

        #expect(hackMiiOption != nil)
        #expect(wilbrandOption != nil)
        guard let hackMiiOption, let wilbrandOption else { return }

        sessionController.homebrewDashboardController.binding(for: hackMiiOption).wrappedValue = true
        sessionController.homebrewDashboardController.perform(.download)
        sessionController.homebrewDashboardController.perform(.save)
        #expect(sessionController.coordinator.isCompleted(.fixed(.chooseItems)))

        sessionController.homebrewDashboardController.binding(for: wilbrandOption).wrappedValue = true

        #expect(sessionController.homebrewDashboardController.actionState == .needsSetup(optionName: "Wilbrand"))
        #expect(!sessionController.coordinator.isCompleted(.fixed(.chooseItems)))
    }

    private func makeSessionController(metadata: DiskVolumeMetadata?) -> WorkflowSessionController {
        makeSessionController(metadataProvider: MutableDiskMetadataProvider(metadata: metadata))
    }

    private func makeSessionController(metadataProvider: MutableDiskMetadataProvider) -> WorkflowSessionController {
        let scopedAccessManager = ScopedAccessManager(accessSessionFactory: FakeSecurityScopedAccessSessionFactory())
        let sdCardValidationService = SDCardValidationService(metadataProvider: metadataProvider)
        let sdSelectionController = SDSelectionController(
            scopedAccessManager: scopedAccessManager,
            sdCardValidationService: sdCardValidationService
        )

        return WorkflowSessionController(
            coordinator: WorkflowCoordinator(),
            sdSelectionController: sdSelectionController
        )
    }
}
