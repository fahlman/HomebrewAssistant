//
//  HomebrewDashboardPreparationTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies Choose Homebrew preparation execution behavior.
//

import Foundation
import Testing
@testable import Homebrew_Assistant

@MainActor
extension HomebrewDashboardControllerTests {
    @Test func performChooseGeneratedArchiveImportsStagesAndExtractsWilbrandZip() async throws {
        let archiveURL = try makeWilbrandArchive()
        let archiveSelector = FakeGeneratedArchiveSelector(selectedArchiveURL: archiveURL)
        let controller = wilbrandController(generatedArchiveSelector: archiveSelector)
        let wilbrandOption = try requireWilbrandOption(in: controller)

        select(wilbrandOption, in: controller)
        await controller.perform(.setUp(optionName: "Wilbrand"))
        await controller.perform(.chooseGeneratedArchive)

        #expect(controller.status(for: wilbrandOption) == .readyToSave)
        #expect(controller.actionState == .readyToSave)
        #expect(controller.preparedPayloadURL(for: wilbrandOption)?.lastPathComponent == "builtIn-wilbrand.zip")
        #expect(controller.extractedPayloadDirectoryURL(for: wilbrandOption)?.path == "/tmp/extracted/builtIn:wilbrand")
    }

    @Test func performSetUpOpensWilbrandBrowserAndWaitsForGeneratedArchive() async throws {
        let browserOpener = FakeBrowserOpener()
        let controller = wilbrandController(browserOpener: browserOpener)
        let wilbrandOption = try requireWilbrandOption(in: controller)

        select(wilbrandOption, in: controller)
        await controller.perform(.setUp(optionName: "Wilbrand"))

        #expect(browserOpener.openedURLs.map(\.absoluteString) == ["https://wilbrand.donut.eu.org"])
        #expect(controller.status(for: wilbrandOption) == .generatedArchiveRequired)
        #expect(controller.actionState == .needsGeneratedArchiveFile)
    }

    @Test func performDownloadMovesReadyToDownloadOptionsToReadyToSave() async throws {
        let controller = downloadableHackMiiController()
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)
        await controller.perform(.download)

        #expect(controller.status(for: hackMiiOption) == .readyToSave)
        #expect(controller.actionState == .readyToSave)
        #expect(controller.preparedPayloadURL(for: hackMiiOption)?.path == "/tmp/hackmii.zip")
        #expect(controller.extractedPayloadDirectoryURL(for: hackMiiOption)?.path == "/tmp/extracted/builtIn:hackMii")
    }

    @Test func performDownloadRecordsSuccessfulDownloadDiagnostics() async throws {
        let diagnosticsStore = HomebrewPreparationDiagnosticsStore()
        let controller = downloadableHackMiiController(diagnosticsStore: diagnosticsStore)
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)
        await controller.perform(.download)

        #expect(controller.preparationDiagnostics.map(\.action) == [
            .downloadRequested,
            .payloadURLDerived,
            .extractionStarted,
            .extractionCompleted,
            .downloadCompleted
        ])
        #expect(controller.preparationDiagnostics.map(\.optionID) == [
            hackMiiOption.id,
            hackMiiOption.id,
            hackMiiOption.id,
            hackMiiOption.id,
            hackMiiOption.id
        ])
    }

    @Test func performDownloadRecordsFailedDownloadDiagnostics() async throws {
        let diagnosticsStore = HomebrewPreparationDiagnosticsStore()
        let controller = downloadableHackMiiController(
            payloadDownloader: ThrowingHomebrewPayloadDownloader(),
            diagnosticsStore: diagnosticsStore
        )
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)
        await controller.perform(.download)

        #expect(controller.status(for: hackMiiOption) == .failed(message: "Download failed for HackMii."))
        #expect(controller.preparationDiagnostics.map(\.action) == [
            .downloadRequested,
            .payloadURLDerived,
            .downloadFailed
        ])
    }

    @Test func performExtractUsesPreparedArchiveAndMovesToReadyToSave() async throws {
        var store = preparationStateStore(
            optionID: HomebrewOptionID.builtIn(.hackMii),
            status: .readyToExtract
        )
        let preparedPayloadURL = URL(fileURLWithPath: "/tmp/hackmii.zip")
        store.setPreparedPayloadURL(
            preparedPayloadURL,
            for: HomebrewOptionID.builtIn(.hackMii)
        )
        let controller = HomebrewDashboardController(
            builtInHomebrewCatalog: BuiltInHomebrewCatalog(definitions: [
                downloadableHackMiiDefinition()
            ]),
            preparationStateStore: store,
            preparationExecutor: ImmediateHomebrewPreparationExecutor(
                archiveExtractor: FakeHomebrewArchiveExtractor()
            )
        )
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)
        await controller.perform(.extract)

        #expect(controller.status(for: hackMiiOption) == .readyToSave)
        #expect(controller.actionState == .readyToSave)
        #expect(controller.preparedPayloadURL(for: hackMiiOption) == preparedPayloadURL)
        #expect(controller.extractedPayloadDirectoryURL(for: hackMiiOption)?.path == "/tmp/extracted/builtIn:hackMii")
    }

    @Test func checksumVerifierAcceptsMatchingSHA256() throws {
        let payloadURL = try makeTemporaryPayload(contents: Data("abc".utf8))
        let verifier = SHA256HomebrewPayloadChecksumVerifier()

        try verifier.verifyDownloadedPayload(
            at: payloadURL,
            expectedSHA256: "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )
    }

    @Test func checksumVerifierRejectsMismatchedSHA256() throws {
        let payloadURL = try makeTemporaryPayload(contents: Data("abc".utf8))
        let verifier = SHA256HomebrewPayloadChecksumVerifier()

        #expect(throws: HomebrewPayloadChecksumError.checksumMismatch(
            expectedSHA256: "0000000000000000000000000000000000000000000000000000000000000000",
            actualSHA256: "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        )) {
            try verifier.verifyDownloadedPayload(
                at: payloadURL,
                expectedSHA256: "0000000000000000000000000000000000000000000000000000000000000000"
            )
        }
    }

    @Test func checksumVerifierRequiresExpectedSHA256() throws {
        let payloadURL = try makeTemporaryPayload(contents: Data("abc".utf8))
        let verifier = SHA256HomebrewPayloadChecksumVerifier()

        #expect(throws: HomebrewPayloadChecksumError.missingExpectedSHA256) {
            try verifier.verifyDownloadedPayload(
                at: payloadURL,
                expectedSHA256: nil
            )
        }
    }

    @Test func performDelegatesToPreparationExecutor() async throws {
        let fakeExecutor = FakeHomebrewPreparationExecutor()
        let controller = HomebrewDashboardController(preparationExecutor: fakeExecutor)
        let hackMiiOption = try requireHackMiiOption(in: controller)
        fakeExecutor.updates = [
            HomebrewPreparationStatusUpdate(
                optionID: hackMiiOption.id,
                newStatus: .readyToSave,
                reason: .downloadCompleted
            )
        ]

        select(hackMiiOption, in: controller)
        await controller.perform(.download)

        #expect(fakeExecutor.performedActions == [.download])
        #expect(fakeExecutor.selectedOptionIDs == [[hackMiiOption.id]])
        #expect(controller.status(for: hackMiiOption) == .readyToSave)
    }

    @Test func performDownloadUpdatesHiddenSelectedOptions() async throws {
        let controller = downloadableHackMiiController()
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)
        controller.selectedCategoryFilter = .category(.exploits)
        await controller.perform(.download)

        let visibleSources = controller.visibleOptions.map(\.source)
        let expectedSources: [HomebrewOption.Source] = []

        #expect(visibleSources == expectedSources)
        #expect(controller.status(for: hackMiiOption) == .readyToSave)
        #expect(controller.actionState == .readyToSave)
    }

    @Test func legacyDownloadedStatusStillOffersSaveAction() throws {
        let controller = HomebrewDashboardController(
            builtInHomebrewCatalog: BuiltInHomebrewCatalog(definitions: [
                downloadableHackMiiDefinition()
            ]),
            preparationStateStore: preparationStateStore(
                optionID: HomebrewOptionID.builtIn(.hackMii),
                status: .downloaded
            )
        )
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)

        #expect(controller.status(for: hackMiiOption) == .downloaded)
        #expect(controller.actionState == .readyToSave)
    }

    @Test func performSaveMovesReadyToSaveOptionsToSaved() async throws {
        let controller = readyToSaveHackMiiController()
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)
        await controller.perform(.save)

        #expect(controller.status(for: hackMiiOption) == .saved)
        #expect(controller.actionState == .complete)
    }

    @Test func preparationActionsRecordObservableStartProgressAndCompletionTransitions() async throws {
        let controller = downloadableHackMiiController()
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)
        await controller.perform(.download)

        let recordedDownloadStart = controller.preparationTransitions.contains {
            $0.optionID == hackMiiOption.id
                && $0.reason == .downloadStarted
                && $0.newStatus == .downloading(progress: 0)
        }
        let recordedDownloadProgress = controller.preparationTransitions.contains {
            $0.optionID == hackMiiOption.id
                && $0.reason == .downloadProgressed
                && $0.newStatus == .downloading(progress: 0.5)
        }
        let recordedDownloadCompletion = controller.preparationTransitions.contains {
            $0.optionID == hackMiiOption.id
                && $0.reason == .downloadCompleted
                && $0.newStatus == .readyToSave
        }

        #expect(recordedDownloadStart)
        #expect(recordedDownloadProgress)
        #expect(recordedDownloadCompletion)
    }

    @Test func performSaveUpdatesHiddenSelectedOptions() async throws {
        let controller = readyToSaveHackMiiController()
        let hackMiiOption = try requireHackMiiOption(in: controller)

        select(hackMiiOption, in: controller)
        controller.selectedCategoryFilter = .category(.exploits)
        await controller.perform(.save)

        let visibleSources = controller.visibleOptions.map(\.source)
        let expectedSources: [HomebrewOption.Source] = []
        let hackMiiStatus = controller.status(for: hackMiiOption)
        let actionState = controller.actionState

        #expect(visibleSources == expectedSources)
        #expect(hackMiiStatus == .saved)
        #expect(actionState == .complete)
    }
}
