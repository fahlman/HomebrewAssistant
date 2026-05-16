//
//  HomebrewDashboardControllerTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies Homebrew dashboard controller option visibility, filtering,
//  selection binding, and preparation status mapping.
//  Covers: Default filter/sort state, category filtering, alphabetical sorting,
//  dashboard option selection updates, initial Wilbrand/HackMii status mapping,
//  injected preparation-state status mapping, filter-independent action-state selection,
//  bottom-bar configuration, and preparation action transitions.
//  Does not cover: Dashboard SwiftUI rendering, public recipe catalog loading,
//  downloads, staging, SD card writes, verification, or workflow navigation.
//

import Foundation
import Testing
@testable import Homebrew_Assistant
internal import SwiftUI

@MainActor
struct HomebrewDashboardControllerTests {
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

    @Test func bindingUpdatesDashboardSelection() throws {
        let controller = HomebrewDashboardController()
        let hackMiiOption = try requireBuiltInOption(.hackMii, in: controller)

        select(hackMiiOption, in: controller)
        #expect(controller.binding(for: hackMiiOption).wrappedValue)

        deselect(hackMiiOption, in: controller)
        #expect(!controller.binding(for: hackMiiOption).wrappedValue)
    }

    @Test func wilbrandStatusReflectsSelection() throws {
        let controller = HomebrewDashboardController()
        let wilbrandOption = try requireBuiltInOption(.wilbrand, in: controller)

        #expect(controller.status(for: wilbrandOption) == .notSelected)

        select(wilbrandOption, in: controller)
        #expect(controller.status(for: wilbrandOption) == .setupRequired)
    }

    @Test func hackMiiStatusReflectsSelection() throws {
        let controller = HomebrewDashboardController()
        let hackMiiOption = try requireBuiltInOption(.hackMii, in: controller)

        #expect(controller.status(for: hackMiiOption) == .notSelected)

        select(hackMiiOption, in: controller)
        #expect(controller.status(for: hackMiiOption) == .readyToDownload)
    }

    @Test func injectedPreparationStatusOverridesInitialStatusForSelectedOption() throws {
        let controller = HomebrewDashboardController(
            preparationStateStore: preparationStateStore(
                optionID: HomebrewOptionID.builtIn(.hackMii),
                status: .downloading(progress: 0.5)
            )
        )
        let hackMiiOption = try requireBuiltInOption(.hackMii, in: controller)

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
        let hackMiiOption = try requireBuiltInOption(.hackMii, in: controller)

        select(hackMiiOption, in: controller)
        deselect(hackMiiOption, in: controller)
        select(hackMiiOption, in: controller)

        #expect(controller.status(for: hackMiiOption) == .readyToDownload)
    }

    @Test func noSelectedHomebrewHasNothingSelectedActionState() {
        let controller = HomebrewDashboardController()

        #expect(controller.actionState == .nothingSelected)
    }

    @Test func nothingSelectedActionStateHasNoBottomBarAction() {
        let controller = HomebrewDashboardController()

        expectNoContextualActions(controller.bottomBarConfiguration)
    }

    @Test func selectedSetupRequiredHomebrewNeedsNamedSetup() throws {
        let controller = HomebrewDashboardController()
        let wilbrandOption = try requireBuiltInOption(.wilbrand, in: controller)

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

    @Test func selectedHackMiiIsReadyToDownload() throws {
        let controller = HomebrewDashboardController()
        let hackMiiOption = try requireBuiltInOption(.hackMii, in: controller)

        select(hackMiiOption, in: controller)

        #expect(controller.actionState == .readyToDownload)
    }

    @Test func hiddenSelectedOptionStillDeterminesActionState() throws {
        let controller = HomebrewDashboardController()
        let hackMiiOption = try requireBuiltInOption(.hackMii, in: controller)

        select(hackMiiOption, in: controller)
        controller.selectedCategoryFilter = .category(.exploits)

        #expect(controller.visibleOptions.map(\.source) == [.builtIn(.wilbrand)])
        #expect(controller.actionState == .readyToDownload)
    }

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

    @Test func wilbrandSetupTakesPriorityOverDownload() throws {
        let controller = HomebrewDashboardController()
        let wilbrandOption = try requireBuiltInOption(.wilbrand, in: controller)
        let hackMiiOption = try requireBuiltInOption(.hackMii, in: controller)

        select(wilbrandOption, in: controller)
        select(hackMiiOption, in: controller)

        #expect(controller.actionState == .needsSetup(optionName: "Wilbrand"))
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

    @Test func performSetUpMovesSetupRequiredHomebrewToReadyToSave() throws {
        let controller = HomebrewDashboardController()
        let wilbrandOption = try requireBuiltInOption(.wilbrand, in: controller)

        select(wilbrandOption, in: controller)
        controller.perform(.setUp(optionName: "Wilbrand"))

        #expect(controller.status(for: wilbrandOption) == .readyToSave)
        #expect(controller.actionState == .readyToSave)
    }

    @Test func performDownloadMovesReadyToDownloadOptionsToReadyToSave() throws {
        let controller = HomebrewDashboardController()
        let hackMiiOption = try requireBuiltInOption(.hackMii, in: controller)

        select(hackMiiOption, in: controller)
        controller.perform(.download)

        #expect(controller.status(for: hackMiiOption) == .readyToSave)
        #expect(controller.actionState == .readyToSave)
    }

    @Test func performDownloadUpdatesHiddenSelectedOptions() throws {
        let controller = HomebrewDashboardController()
        let hackMiiOption = try requireBuiltInOption(.hackMii, in: controller)

        select(hackMiiOption, in: controller)
        controller.selectedCategoryFilter = .category(.exploits)
        controller.perform(.download)

        #expect(controller.visibleOptions.map(\.source) == [.builtIn(.wilbrand)])
        #expect(controller.status(for: hackMiiOption) == .readyToSave)
        #expect(controller.actionState == .readyToSave)
    }

    @Test func performSaveMovesReadyToSaveOptionsToSaved() throws {
        let controller = HomebrewDashboardController()
        let hackMiiOption = try requireBuiltInOption(.hackMii, in: controller)

        select(hackMiiOption, in: controller)
        controller.perform(.download)
        controller.perform(.save)

        #expect(controller.status(for: hackMiiOption) == .saved)
        #expect(controller.actionState == .complete)
    }

    @Test func performSaveUpdatesHiddenSelectedOptions() throws {
        let controller = HomebrewDashboardController()
        let hackMiiOption = try requireBuiltInOption(.hackMii, in: controller)

        select(hackMiiOption, in: controller)
        controller.perform(.download)
        controller.selectedCategoryFilter = .category(.exploits)
        controller.perform(.save)

        #expect(controller.visibleOptions.map(\.source) == [.builtIn(.wilbrand)])
        #expect(controller.status(for: hackMiiOption) == .saved)
        #expect(controller.actionState == .complete)
    }

    @Test func completeActionStateHasNoBottomBarAction() {
        let configuration = HomebrewDashboardActionState.complete.bottomBarConfiguration(
            controller: HomebrewDashboardController()
        )

        expectNoContextualActions(configuration)
    }

    private func requireBuiltInOption(
        _ kind: BuiltInHomebrewKind,
        in controller: HomebrewDashboardController
    ) throws -> HomebrewOption {
        try #require(controller.visibleOptions.first { option in
            option.source == .builtIn(kind)
        })
    }

    private func select(
        _ option: HomebrewOption,
        in controller: HomebrewDashboardController
    ) {
        controller.binding(for: option).wrappedValue = true
    }

    private func deselect(
        _ option: HomebrewOption,
        in controller: HomebrewDashboardController
    ) {
        controller.binding(for: option).wrappedValue = false
    }

    private func preparationStateStore(
        optionID: HomebrewOption.ID,
        status: HomebrewPreparationStatus
    ) -> HomebrewPreparationStateStore {
        var preparationStateStore = HomebrewPreparationStateStore()
        preparationStateStore[optionID] = status
        return preparationStateStore
    }

    private func catalogWithTwoSetupRequiredPublicRecipes() -> BuiltInHomebrewCatalog {
        BuiltInHomebrewCatalog(definitions: [
            HomebrewDefinition(
                id: HomebrewOptionID.publicRecipe("setup-one"),
                name: "Setup One",
                summaryKey: "chooseHomebrew.wilbrand.description",
                category: .exploits,
                systemImageName: "ladybug",
                sortOrder: 100,
                preparationKind: .setupRequired,
                source: .publicRecipe(id: "setup-one")
            ),
            HomebrewDefinition(
                id: HomebrewOptionID.publicRecipe("setup-two"),
                name: "Setup Two",
                summaryKey: "chooseHomebrew.hackMii.description",
                category: .utilities,
                systemImageName: "wrench",
                sortOrder: 101,
                preparationKind: .setupRequired,
                source: .publicRecipe(id: "setup-two")
            )
        ])
    }

    private func expectNoContextualActions(_ configuration: WorkflowBottomBarConfiguration) {
        #expect(configuration.contextualActions.isEmpty)
        #expect(configuration.canGoForwardOverride == nil)
        #expect(configuration.defaultAction == nil)
    }

    private func expectSingleContextualAction(
        _ configuration: WorkflowBottomBarConfiguration,
        titleKey: String,
        titleArguments: [String] = [],
        systemImageName: String?
    ) {
        #expect(configuration.contextualActions.map(\.titleKey) == [
            titleKey
        ])
        #expect(configuration.contextualActions.map(\.titleArguments) == [
            titleArguments
        ])
        #expect(configuration.contextualActions.map(\.systemImageName) == [
            systemImageName
        ])
        #expect(configuration.canGoForwardOverride == false)
        #expect(configuration.defaultAction == .contextualAction(index: 0))
    }
}
