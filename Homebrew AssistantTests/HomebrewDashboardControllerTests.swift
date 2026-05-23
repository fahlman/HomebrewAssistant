//
//  HomebrewDashboardControllerTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies Homebrew dashboard controller option visibility, filtering,
//  selection state updates, and preparation status mapping.
//  Covers: Default filter/sort state, category filtering, alphabetical sorting,
//  dashboard option selection updates, built-in preparation status mapping,
//  injected preparation-state status mapping, filter-independent action-state selection,
//  bottom-bar configuration, setup/download action priority, and completion
//  bottom-bar policy.
//  Does not cover: Dashboard SwiftUI rendering, public recipe catalog loading,
//  downloads, staging, SD card writes, verification, or workflow navigation.
//

import Foundation
import Testing
@testable import Homebrew_Assistant

@MainActor
struct HomebrewDashboardControllerTests {
    // MARK: - Visibility and Sorting

    @Test func defaultStateShowsBuiltInHomebrewOptionsInCategoryOrder() {
        let controller = HomebrewDashboardController()

        #expect(controller.selectedCategoryFilter == .all)
        #expect(controller.selectedSortMode == .category)
        #expect(controller.visibleOptions.map(\.source) == [
            .builtIn(.wilbrand),
            .builtIn(.hackMii)
        ])
    }

    @Test func categoryFilterLimitsVisibleOptions() {
        let controller = HomebrewDashboardController()

        controller.selectedCategoryFilter = .category(.exploits)

        #expect(controller.visibleOptions.map(\.source) == [.builtIn(.wilbrand)])
    }

    @Test func alphabeticalSortOrdersVisibleOptionsByName() {
        let controller = HomebrewDashboardController()

        controller.selectedSortMode = .alphabetical

        let optionNames = controller.visibleOptions.map(\.name)
        #expect(optionNames == optionNames.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        })
    }

    // MARK: - Selection and Status

    @Test func setOptionUpdatesDashboardSelection() throws {
        let controller = HomebrewDashboardController()
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)
        #expect(controller.isSelected(hackMiiOption))

        deselect(hackMiiOption, in: controller)
        #expect(!controller.isSelected(hackMiiOption))
    }

    @Test func wilbrandStatusReflectsSelection() throws {
        let controller = HomebrewDashboardController()
        let wilbrandOption = try requireWilbrandOption(in: controller)

        #expect(controller.status(for: wilbrandOption) == .notSelected)

        select(wilbrandOption, in: controller)
        #expect(controller.status(for: wilbrandOption) == .setupRequired)
    }

    @Test func hackMiiStatusReflectsSelection() throws {
        let controller = HomebrewDashboardController()
        let hackMiiOption = try requireHackMiiOption(in: controller)

        #expect(controller.status(for: hackMiiOption) == .notSelected)

        select(hackMiiOption, in: controller)
        #expect(controller.status(for: hackMiiOption) == .readyToDownload)
    }

    @Test func setOptionRecordsPreparationTransitions() throws {
        let controller = HomebrewDashboardController()
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)
        deselect(hackMiiOption, in: controller)

        #expect(controller.preparationTransitions == [
            HomebrewPreparationStateTransition(
                optionID: hackMiiOption.id,
                optionName: hackMiiOption.name,
                previousStatus: .notSelected,
                newStatus: .readyToDownload,
                reason: .selected
            ),
            HomebrewPreparationStateTransition(
                optionID: hackMiiOption.id,
                optionName: hackMiiOption.name,
                previousStatus: .readyToDownload,
                newStatus: .notSelected,
                reason: .deselected
            )
        ])
    }

    // MARK: - Injected Preparation State

    @Test func injectedPreparationStatusOverridesInitialStatusForSelectedOption() throws {
        let controller = HomebrewDashboardController(
            preparationStateStore: preparationStateStore(
                optionID: HomebrewOptionID.builtIn(.hackMii),
                status: .downloading(progress: 0.5)
            )
        )
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)

        #expect(controller.status(for: hackMiiOption) == .downloading(progress: 0.5))
    }

    @Test func deselectingAndReselectingOptionResetsPreparationStatus() throws {
        let controller = HomebrewDashboardController(
            preparationStateStore: preparationStateStore(
                optionID: HomebrewOptionID.builtIn(.hackMii),
                status: .downloading(progress: 0.5)
            )
        )
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)
        deselect(hackMiiOption, in: controller)
        select(hackMiiOption, in: controller)

        #expect(controller.status(for: hackMiiOption) == .readyToDownload)
    }

    @Test func reconciledPreparedStateSelectsRestoredHomebrew() throws {
        var reconciledStateStore = HomebrewPreparationStateStore()
        let payloadURL = URL(fileURLWithPath: "/tmp/hackmii.zip")
        let extractedURL = URL(fileURLWithPath: "/tmp/extracted/builtIn-hackMii")
        reconciledStateStore[HomebrewOptionID.builtIn(.hackMii)] = .readyToSave
        reconciledStateStore.setPreparedPayloadURL(
            payloadURL,
            for: HomebrewOptionID.builtIn(.hackMii)
        )
        reconciledStateStore.setExtractedPayloadDirectoryURL(
            extractedURL,
            for: HomebrewOptionID.builtIn(.hackMii)
        )
        let controller = HomebrewDashboardController()
        controller.reconcilePreparedState(
            using: FakeHomebrewPreparationStateReconciler(
                reconciledState: ReconciledHomebrewPreparationState(
                    selectedOptionIDs: [HomebrewOptionID.builtIn(.hackMii)],
                    preparationStateStore: reconciledStateStore
                )
            )
        )
        let hackMiiOption = try requireHackMiiOption(in: controller)

        #expect(controller.isSelected(hackMiiOption))
        #expect(controller.status(for: hackMiiOption) == .readyToSave)
        #expect(controller.preparedPayloadURL(for: hackMiiOption) == payloadURL)
        #expect(controller.extractedPayloadDirectoryURL(for: hackMiiOption) == extractedURL)
        #expect(controller.actionState == .readyToSave)
    }

    @Test func reconciledMissingDownloadResetsRestoredDownloadableHomebrew() throws {
        let controller = HomebrewDashboardController(
            preparationStateStore: preparationStateStore(
                optionID: HomebrewOptionID.builtIn(.hackMii),
                status: .readyToSave
            ),
            selectedOptionIDs: [HomebrewOptionID.builtIn(.hackMii)]
        )
        let hackMiiOption = try requireHackMiiOption(in: controller)

        controller.reconcilePreparedState(
            using: FakeHomebrewPreparationStateReconciler(
                reconciledState: ReconciledHomebrewPreparationState(
                    selectedOptionIDs: [],
                    preparationStateStore: HomebrewPreparationStateStore()
                )
            )
        )

        #expect(controller.isSelected(hackMiiOption))
        #expect(controller.status(for: hackMiiOption) == .readyToDownload)
        #expect(controller.actionState == .readyToDownload)
    }

    @Test func reconciledMissingGeneratedArchiveResetsWilbrandSetup() throws {
        let controller = HomebrewDashboardController(
            preparationStateStore: preparationStateStore(
                optionID: HomebrewOptionID.builtIn(.wilbrand),
                status: .generatedArchiveRequired
            ),
            selectedOptionIDs: [HomebrewOptionID.builtIn(.wilbrand)]
        )
        let wilbrandOption = try requireWilbrandOption(in: controller)

        controller.reconcilePreparedState(
            using: FakeHomebrewPreparationStateReconciler(
                reconciledState: ReconciledHomebrewPreparationState(
                    selectedOptionIDs: [],
                    preparationStateStore: HomebrewPreparationStateStore()
                )
            )
        )

        #expect(controller.isSelected(wilbrandOption))
        #expect(controller.status(for: wilbrandOption) == .setupRequired)
        #expect(controller.actionState == .needsSetup(optionName: "Wilbrand"))
    }

    @Test func reconciledCleanupActionsRemoveStaleExtractedPayloads() throws {
        let extractedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("builtIn-hackMii", isDirectory: true)
        try FileManager.default.createDirectory(
            at: extractedURL,
            withIntermediateDirectories: true
        )
        try Data("stale".utf8).write(
            to: extractedURL.appendingPathComponent("boot.elf")
        )
        let controller = HomebrewDashboardController()

        controller.reconcilePreparedState(
            using: FakeHomebrewPreparationStateReconciler(
                reconciledState: ReconciledHomebrewPreparationState(
                    selectedOptionIDs: [],
                    preparationStateStore: HomebrewPreparationStateStore(),
                    cleanupActions: [
                        .removeStaleExtraction(
                            optionID: HomebrewOptionID.builtIn(.hackMii),
                            url: extractedURL
                        )
                    ]
                )
            )
        )

        #expect(!FileManager.default.fileExists(atPath: extractedURL.path))
    }

    // MARK: - Action State

    @Test func noSelectedHomebrewHasNothingSelectedActionState() {
        let controller = HomebrewDashboardController()

        #expect(controller.actionState == .nothingSelected)
    }

    @Test func nothingSelectedActionStateHasNoBottomBarAction() {
        let controller = HomebrewDashboardController()

        expectNoContextualActions(controller.bottomBarConfiguration)
    }

    // MARK: - Setup and Download Policy

    @Test func selectedSetupRequiredHomebrewNeedsNamedSetup() throws {
        let controller = HomebrewDashboardController()
        let wilbrandOption = try requireWilbrandOption(in: controller)

        select(wilbrandOption, in: controller)

        #expect(controller.actionState == .needsSetup(optionName: "Wilbrand"))
    }

    @Test func namedSetupBottomBarUsesSetupNameAction() {
        let action = HomebrewPreparationAction.setUp(optionName: "Wilbrand")
        let configuration = HomebrewDashboardActionState.needsSetup(optionName: "Wilbrand").bottomBarConfiguration(
            controller: HomebrewDashboardController()
        )

        expectSingleContextualAction(
            configuration,
            titleKey: action.titleKey,
            titleArguments: action.titleArguments,
            systemImageName: action.systemImageName
        )
    }

    @Test func selectedDownloadableHomebrewIsReadyToDownload() throws {
        let controller = HomebrewDashboardController()
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)

        #expect(controller.actionState == .readyToDownload)
    }

    @Test func hiddenSelectedOptionStillDeterminesActionState() throws {
        let controller = HomebrewDashboardController()
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)
        controller.selectedCategoryFilter = .category(.exploits)

        #expect(controller.visibleOptions.map(\.source) == [.builtIn(.wilbrand)])
        #expect(controller.actionState == .readyToDownload)
    }

    @Test func selectedDownloadingHomebrewHasDownloadingActionState() throws {
        let controller = HomebrewDashboardController(
            preparationStateStore: preparationStateStore(
                optionID: HomebrewOptionID.builtIn(.hackMii),
                status: .downloading(progress: 0.5)
            )
        )
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)

        #expect(controller.actionState == .downloading)
    }

    @Test func selectedExtractingHomebrewHasExtractingActionState() throws {
        let controller = HomebrewDashboardController(
            preparationStateStore: preparationStateStore(
                optionID: HomebrewOptionID.builtIn(.hackMii),
                status: .extracting
            )
        )
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)

        #expect(controller.actionState == .extracting)
    }

    @Test func busyPreparationTakesPriorityOverOtherAvailableActions() throws {
        let controller = HomebrewDashboardController(
            preparationStateStore: preparationStateStore(
                optionID: HomebrewOptionID.builtIn(.hackMii),
                status: .downloading(progress: 0.5)
            )
        )
        let wilbrandOption = try requireWilbrandOption(in: controller)
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(wilbrandOption, in: controller)
        select(hackMiiOption, in: controller)

        #expect(controller.actionState == .downloading)
    }

    // MARK: - Bottom Bar

    @Test func readyToDownloadBottomBarUsesDownloadAction() {
        let configuration = HomebrewDashboardActionState.readyToDownload.bottomBarConfiguration(
            controller: HomebrewDashboardController()
        )

        expectSingleContextualAction(
            configuration,
            titleKey: HomebrewPreparationAction.download.titleKey,
            systemImageName: HomebrewPreparationAction.download.systemImageName
        )
    }

    @Test func readyToExtractBottomBarUsesExtractAction() {
        let configuration = HomebrewDashboardActionState.readyToExtract.bottomBarConfiguration(
            controller: HomebrewDashboardController()
        )

        expectSingleContextualAction(
            configuration,
            titleKey: HomebrewPreparationAction.extract.titleKey,
            systemImageName: HomebrewPreparationAction.extract.systemImageName
        )
    }

    @Test func generatedArchiveRequiredBottomBarUsesChooseFileAction() {
        let configuration = HomebrewDashboardActionState.needsGeneratedArchiveFile.bottomBarConfiguration(
            controller: HomebrewDashboardController()
        )

        expectSingleContextualAction(
            configuration,
            titleKey: HomebrewPreparationAction.chooseGeneratedArchive.titleKey,
            systemImageName: HomebrewPreparationAction.chooseGeneratedArchive.systemImageName
        )
    }

    @Test func readyToSaveBottomBarUsesSaveAction() {
        let configuration = HomebrewDashboardActionState.readyToSave.bottomBarConfiguration(
            controller: HomebrewDashboardController()
        )

        expectSingleContextualAction(
            configuration,
            titleKey: HomebrewPreparationAction.save.titleKey,
            systemImageName: HomebrewPreparationAction.save.systemImageName
        )
    }

    @Test func busyBottomBarHasNoActionsAndCannotGoForward() {
        let configurations = [
            HomebrewDashboardActionState.downloading,
            .extracting,
            .saving
        ].map { actionState in
            actionState.bottomBarConfiguration(controller: HomebrewDashboardController())
        }

        for configuration in configurations {
            #expect(configuration.contextualActions.isEmpty)
            #expect(configuration.canGoForwardOverride == false)
            #expect(configuration.defaultAction == nil)
        }
    }

    @Test func setupRequiredSelectionTakesPriorityOverDownload() throws {
        let controller = HomebrewDashboardController()
        let wilbrandOption = try requireWilbrandOption(in: controller)
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(wilbrandOption, in: controller)
        select(hackMiiOption, in: controller)

        #expect(controller.actionState == .needsSetup(optionName: "Wilbrand"))
    }

    @Test func generatedArchiveSelectionTakesPriorityOverDownloadUntilWilbrandIsReadyToSave() async throws {
        let controller = wilbrandAndHackMiiController()
        let wilbrandOption = try requireWilbrandOption(in: controller)
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(wilbrandOption, in: controller)
        select(hackMiiOption, in: controller)
        await controller.perform(.setUp(optionName: "Wilbrand"))

        #expect(controller.status(for: wilbrandOption) == .generatedArchiveRequired)
        #expect(controller.status(for: hackMiiOption) == .readyToDownload)
        #expect(controller.actionState == .needsGeneratedArchiveFile)
    }

    @Test func hackMiiDownloadBecomesAvailableAfterWilbrandImport() async throws {
        let archiveURL = try makeWilbrandArchive()
        let controller = wilbrandAndHackMiiController(
            generatedArchiveSelector: FakeGeneratedArchiveSelector(selectedArchiveURL: archiveURL)
        )
        let wilbrandOption = try requireWilbrandOption(in: controller)
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(wilbrandOption, in: controller)
        select(hackMiiOption, in: controller)
        await controller.perform(.setUp(optionName: "Wilbrand"))
        await controller.perform(.chooseGeneratedArchive)

        #expect(controller.status(for: wilbrandOption) == .readyToSave)
        #expect(controller.status(for: hackMiiOption) == .readyToDownload)
        #expect(controller.actionState == .readyToDownload)
    }

    @Test func multipleSetupRequiredHomebrewNeedsGenericSetup() {
        let controller = HomebrewDashboardController(
            builtInHomebrewCatalog: catalogWithTwoSetupRequiredPublicRecipes()
        )

        for option in controller.visibleOptions {
            select(option, in: controller)
        }

        let configuration = controller.bottomBarConfiguration

        #expect(controller.actionState == .needsSetup(optionName: nil))
        #expect(configuration.contextualActions.map(\.titleKey) == [
            HomebrewPreparationAction.setUp(optionName: nil).titleKey
        ])
        #expect(configuration.contextualActions.map(\.titleArguments) == [[]])
    }

    @Test func completeActionStateHasNoBottomBarAction() {
        let configuration = HomebrewDashboardActionState.complete.bottomBarConfiguration(
            controller: HomebrewDashboardController()
        )

        expectNoContextualActions(configuration)
    }
}
