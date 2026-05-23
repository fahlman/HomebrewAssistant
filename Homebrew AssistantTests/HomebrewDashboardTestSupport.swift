//
//  HomebrewDashboardTestSupport.swift
//  Homebrew Assistant Tests
//
//  Purpose: Shared helpers and fakes for Homebrew dashboard controller tests.
//

import Foundation
import Testing
import ZIPFoundation
@testable import Homebrew_Assistant

@MainActor
extension HomebrewDashboardControllerTests {
    func requireWilbrandOption(in controller: HomebrewDashboardController) throws -> HomebrewOption {
        try requireBuiltInOption(.wilbrand, in: controller)
    }

    func requireHackMiiOption(in controller: HomebrewDashboardController) throws -> HomebrewOption {
        try requireBuiltInOption(.hackMii, in: controller)
    }

    func requireBuiltInOption(
        _ kind: BuiltInHomebrewKind,
        in controller: HomebrewDashboardController
    ) throws -> HomebrewOption {
        try #require(controller.visibleOptions.first { option in
            option.source == .builtIn(kind)
        })
    }

    func select(
        _ option: HomebrewOption,
        in controller: HomebrewDashboardController
    ) {
        controller.setOption(option, isSelected: true)
    }

    func deselect(
        _ option: HomebrewOption,
        in controller: HomebrewDashboardController
    ) {
        controller.setOption(option, isSelected: false)
    }

    func preparationStateStore(
        optionID: HomebrewOption.ID,
        status: HomebrewPreparationStatus
    ) -> HomebrewPreparationStateStore {
        var preparationStateStore = HomebrewPreparationStateStore()
        preparationStateStore[optionID] = status
        return preparationStateStore
    }

    func makeTemporaryPayload(contents: Data) throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        let payloadURL = directoryURL.appendingPathComponent("payload.bin")
        try contents.write(to: payloadURL)
        return payloadURL
    }

    func makeWilbrandArchive() throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sourceURL = directoryURL.appendingPathComponent("source", isDirectory: true)
        let privateTitleURL = sourceURL
            .appendingPathComponent("private", isDirectory: true)
            .appendingPathComponent("wii", isDirectory: true)
            .appendingPathComponent("title", isDirectory: true)
            .appendingPathComponent("HAEA", isDirectory: true)
        try FileManager.default.createDirectory(
            at: privateTitleURL,
            withIntermediateDirectories: true
        )
        try Data("message".utf8).write(
            to: privateTitleURL.appendingPathComponent("content.bin")
        )

        let archiveURL = directoryURL.appendingPathComponent("wilbrand.zip")
        try FileManager.default.zipItem(
            at: sourceURL,
            to: archiveURL,
            shouldKeepParent: false,
            compressionMethod: .deflate
        )
        return archiveURL
    }

    func wilbrandAndHackMiiController(
        generatedArchiveSelector: any GeneratedArchiveSelecting = FakeGeneratedArchiveSelector(selectedArchiveURL: nil)
    ) -> HomebrewDashboardController {
        HomebrewDashboardController(
            preparationExecutor: ImmediateHomebrewPreparationExecutor(
                browserOpener: FakeBrowserOpener(),
                generatedArchiveSelector: generatedArchiveSelector
            )
        )
    }

    func wilbrandController(
        browserOpener: any BrowserOpening = FakeBrowserOpener(),
        generatedArchiveSelector: any GeneratedArchiveSelecting = FakeGeneratedArchiveSelector(selectedArchiveURL: nil),
        archiveExtractor: any HomebrewArchiveExtracting = FakeHomebrewArchiveExtractor()
    ) -> HomebrewDashboardController {
        HomebrewDashboardController(
            builtInHomebrewCatalog: BuiltInHomebrewCatalog(definitions: [
                WilbrandHomebrewDefinition.definition
            ]),
            preparationExecutor: ImmediateHomebrewPreparationExecutor(
                archiveExtractor: archiveExtractor,
                browserOpener: browserOpener,
                generatedArchiveSelector: generatedArchiveSelector
            )
        )
    }

    func downloadableHackMiiController(
        payloadDownloader: any HomebrewPayloadDownloading = FakeHomebrewPayloadDownloader(),
        archiveExtractor: any HomebrewArchiveExtracting = FakeHomebrewArchiveExtractor(),
        diagnosticsStore: HomebrewPreparationDiagnosticsStore? = nil
    ) -> HomebrewDashboardController {
        HomebrewDashboardController(
            builtInHomebrewCatalog: BuiltInHomebrewCatalog(definitions: [
                downloadableHackMiiDefinition()
            ]),
            diagnosticsStore: diagnosticsStore,
            preparationExecutor: ImmediateHomebrewPreparationExecutor(
                payloadDownloader: payloadDownloader,
                archiveExtractor: archiveExtractor,
                diagnosticsRecorder: diagnosticsStore
            )
        )
    }

    func readyToSaveHackMiiController() -> HomebrewDashboardController {
        HomebrewDashboardController(
            builtInHomebrewCatalog: BuiltInHomebrewCatalog(definitions: [
                downloadableHackMiiDefinition()
            ]),
            preparationStateStore: preparationStateStore(
                optionID: HomebrewOptionID.builtIn(.hackMii),
                status: .readyToSave
            )
        )
    }

    func downloadableHackMiiDefinition() -> HomebrewDefinition {
        HomebrewDefinition(
            id: HomebrewOptionID.builtIn(.hackMii),
            name: "HackMii",
            summaryKey: "chooseHomebrew.hackMii.description",
            category: .installers,
            systemImageName: "hammer",
            sortOrder: 101,
            preparationKind: .downloadable,
            downloadRequest: HomebrewDownloadRequest(
                approvedBaseURL: URL(string: "https://example.com/")!,
                payloadFileName: "hackmii.zip",
                expectedSHA256: "fake-test-downloader-does-not-read-this"
            ),
            source: .builtIn(.hackMii)
        )
    }

    func catalogWithTwoSetupRequiredPublicRecipes() -> BuiltInHomebrewCatalog {
        BuiltInHomebrewCatalog(definitions: [
            setupRequiredPublicRecipeDefinition(
                id: "setup-one",
                name: "Setup One",
                category: .exploits,
                systemImageName: "ladybug",
                sortOrder: 100
            ),
            setupRequiredPublicRecipeDefinition(
                id: "setup-two",
                name: "Setup Two",
                category: .utilities,
                systemImageName: "wrench",
                sortOrder: 101
            )
        ])
    }

    func setupRequiredPublicRecipeDefinition(
        id: String,
        name: String,
        category: HomebrewCategory,
        systemImageName: String,
        sortOrder: Int
    ) -> HomebrewDefinition {
        HomebrewDefinition(
            id: HomebrewOptionID.publicRecipe(id),
            name: name,
            summaryKey: "chooseHomebrew.wilbrand.description",
            category: category,
            systemImageName: systemImageName,
            sortOrder: sortOrder,
            preparationKind: .setupRequired,
            downloadRequest: nil,
            source: .publicRecipe(id: id)
        )
    }

    func expectNoContextualActions(_ configuration: WorkflowBottomBarConfiguration) {
        #expect(configuration.contextualActions.isEmpty)
        #expect(configuration.canGoForwardOverride == nil)
        #expect(configuration.defaultAction == nil)
    }

    func expectSingleContextualAction(
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

final class FakeHomebrewPreparationExecutor: HomebrewPreparationExecutor {
    var performedActions: [HomebrewPreparationAction] = []
    var selectedOptionIDs: [[HomebrewOption.ID]] = []
    var updates: [HomebrewPreparationStatusUpdate] = []

    func updates(
        _ action: HomebrewPreparationAction,
        for selectedOptions: [HomebrewOption],
        currentStatus: @escaping (HomebrewOption) -> HomebrewPreparationStatus,
        preparedPayloadURL: @escaping (HomebrewOption) -> URL?
    ) -> AsyncStream<HomebrewPreparationStatusUpdate> {
        AsyncStream { continuation in
            performedActions.append(action)
            selectedOptionIDs.append(selectedOptions.map(\.id))
            for update in updates {
                continuation.yield(update)
            }
            continuation.finish()
        }
    }
}

final class FakeBrowserOpener: BrowserOpening {
    var openedURLs: [URL] = []

    func open(_ url: URL) {
        openedURLs.append(url)
    }
}

struct FakeGeneratedArchiveSelector: GeneratedArchiveSelecting {
    let selectedArchiveURL: URL?

    func selectGeneratedArchive(for option: HomebrewOption) async throws -> URL? {
        selectedArchiveURL
    }
}

struct FakeHomebrewPayloadDownloader: HomebrewPayloadDownloading {
    func download(
        _ request: HomebrewDownloadRequest,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        progress(0.5)
        return URL(fileURLWithPath: "/tmp/\(request.payloadFileName)")
    }
}

struct ThrowingHomebrewPayloadDownloader: HomebrewPayloadDownloading {
    func download(
        _ request: HomebrewDownloadRequest,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        throw HomebrewDownloadError.invalidResponse
    }
}

struct FakeHomebrewArchiveExtractor: HomebrewArchiveExtracting {
    func extractArchive(
        at archiveURL: URL,
        for option: HomebrewOption
    ) async throws -> URL {
        URL(fileURLWithPath: "/tmp/extracted/\(option.id.rawValue)")
    }
}

struct FakeHomebrewPreparationStateReconciler: HomebrewPreparationStateReconciling {
    let reconciledState: ReconciledHomebrewPreparationState

    func reconciledState(for options: [HomebrewOption]) -> ReconciledHomebrewPreparationState {
        reconciledState
    }
}
