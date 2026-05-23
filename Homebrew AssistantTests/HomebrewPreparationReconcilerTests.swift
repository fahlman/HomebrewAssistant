//
//  HomebrewPreparationReconcilerTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies startup restoration from staged homebrew preparation files.
//

import Foundation
import Testing
@testable import Homebrew_Assistant

@MainActor
struct HomebrewPreparationReconcilerTests {
    @Test func downloadablePayloadIsRestoredOnlyAfterChecksumVerification() throws {
        let rootURL = try makeTemporaryDirectory()
        let option = downloadableOption()
        let payloadURL = rootURL
            .appendingPathComponent("Homebrew Assistant", isDirectory: true)
            .appendingPathComponent("Downloads", isDirectory: true)
            .appendingPathComponent("hackmii.zip", isDirectory: false)
        let extractedURL = rootURL
            .appendingPathComponent("Homebrew Assistant", isDirectory: true)
            .appendingPathComponent("Extracted", isDirectory: true)
            .appendingPathComponent("builtIn-hackMii", isDirectory: true)
        try FileManager.default.createDirectory(
            at: payloadURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: extractedURL,
            withIntermediateDirectories: true
        )
        try Data("payload".utf8).write(to: payloadURL)
        try Data("extracted".utf8).write(
            to: extractedURL.appendingPathComponent("boot.elf")
        )
        let checksumVerifier = RecordingChecksumVerifier()
        let reconciler = ApplicationSupportHomebrewPreparationReconciler(
            checksumVerifier: checksumVerifier,
            applicationSupportDirectory: rootURL
        )

        let reconciledState = reconciler.reconciledState(for: [option])

        #expect(checksumVerifier.verifiedPayloadURLs == [payloadURL])
        #expect(checksumVerifier.expectedSHA256Values == ["expected-sha"])
        #expect(reconciledState.selectedOptionIDs == [option.id])
        #expect(reconciledState.preparationStateStore[option.id] == .readyToSave)
        #expect(reconciledState.preparationStateStore.preparedPayloadURL(for: option.id) == payloadURL)
        #expect(reconciledState.preparationStateStore.extractedPayloadDirectoryURL(for: option.id) == extractedURL)
    }

    @Test func checksumFailurePreventsDownloadRestore() throws {
        let rootURL = try makeTemporaryDirectory()
        let option = downloadableOption()
        let payloadURL = rootURL
            .appendingPathComponent("Homebrew Assistant", isDirectory: true)
            .appendingPathComponent("Downloads", isDirectory: true)
            .appendingPathComponent("hackmii.zip", isDirectory: false)
        let extractedURL = rootURL
            .appendingPathComponent("Homebrew Assistant", isDirectory: true)
            .appendingPathComponent("Extracted", isDirectory: true)
            .appendingPathComponent("builtIn-hackMii", isDirectory: true)
        try FileManager.default.createDirectory(
            at: payloadURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: extractedURL,
            withIntermediateDirectories: true
        )
        try Data("payload".utf8).write(to: payloadURL)
        try Data("extracted".utf8).write(
            to: extractedURL.appendingPathComponent("boot.elf")
        )
        let reconciler = ApplicationSupportHomebrewPreparationReconciler(
            checksumVerifier: ThrowingChecksumVerifier(),
            applicationSupportDirectory: rootURL
        )

        let reconciledState = reconciler.reconciledState(for: [option])

        #expect(reconciledState.selectedOptionIDs.isEmpty)
        #expect(reconciledState.preparationStateStore[option.id] == .notSelected)
    }

    @Test func missingDownloadRemovesStaleExtractedPayload() throws {
        let rootURL = try makeTemporaryDirectory()
        let option = downloadableOption()
        let extractedURL = rootURL
            .appendingPathComponent("Homebrew Assistant", isDirectory: true)
            .appendingPathComponent("Extracted", isDirectory: true)
            .appendingPathComponent("builtIn-hackMii", isDirectory: true)
        try FileManager.default.createDirectory(
            at: extractedURL,
            withIntermediateDirectories: true
        )
        try Data("extracted".utf8).write(
            to: extractedURL.appendingPathComponent("boot.elf")
        )
        let reconciler = ApplicationSupportHomebrewPreparationReconciler(
            applicationSupportDirectory: rootURL
        )

        let reconciledState = reconciler.reconciledState(for: [option])

        #expect(reconciledState.selectedOptionIDs.isEmpty)
        #expect(reconciledState.cleanupActions == [
            .removeStaleExtraction(optionID: option.id, url: extractedURL)
        ])
        #expect(FileManager.default.fileExists(atPath: extractedURL.path))
    }

    @Test func invalidImportedArchiveRemovesStaleWilbrandExtractedPayload() throws {
        let rootURL = try makeTemporaryDirectory()
        let option = setupRequiredOption()
        let importedURL = rootURL
            .appendingPathComponent("Homebrew Assistant", isDirectory: true)
            .appendingPathComponent("Imported", isDirectory: true)
            .appendingPathComponent("builtIn-wilbrand.zip", isDirectory: false)
        let extractedURL = rootURL
            .appendingPathComponent("Homebrew Assistant", isDirectory: true)
            .appendingPathComponent("Extracted", isDirectory: true)
            .appendingPathComponent("builtIn-wilbrand", isDirectory: true)
        try FileManager.default.createDirectory(
            at: importedURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: extractedURL,
            withIntermediateDirectories: true
        )
        try Data("not a valid wilbrand archive".utf8).write(to: importedURL)
        try Data("extracted".utf8).write(
            to: extractedURL.appendingPathComponent("private", isDirectory: false)
        )
        let reconciler = ApplicationSupportHomebrewPreparationReconciler(
            applicationSupportDirectory: rootURL
        )

        let reconciledState = reconciler.reconciledState(for: [option])

        #expect(reconciledState.selectedOptionIDs.isEmpty)
        #expect(reconciledState.cleanupActions == [
            .removeStaleExtraction(optionID: option.id, url: extractedURL)
        ])
        #expect(FileManager.default.fileExists(atPath: extractedURL.path))
    }

    @Test func validDownloadWithMissingExtractionIsReadyToExtract() throws {
        let rootURL = try makeTemporaryDirectory()
        let option = downloadableOption()
        let payloadURL = rootURL
            .appendingPathComponent("Homebrew Assistant", isDirectory: true)
            .appendingPathComponent("Downloads", isDirectory: true)
            .appendingPathComponent("hackmii.zip", isDirectory: false)
        try FileManager.default.createDirectory(
            at: payloadURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("payload".utf8).write(to: payloadURL)
        let checksumVerifier = RecordingChecksumVerifier()
        let reconciler = ApplicationSupportHomebrewPreparationReconciler(
            checksumVerifier: checksumVerifier,
            applicationSupportDirectory: rootURL
        )

        let reconciledState = reconciler.reconciledState(for: [option])

        #expect(checksumVerifier.verifiedPayloadURLs == [payloadURL])
        #expect(reconciledState.selectedOptionIDs == [option.id])
        #expect(reconciledState.preparationStateStore[option.id] == .readyToExtract)
        #expect(reconciledState.preparationStateStore.preparedPayloadURL(for: option.id) == payloadURL)
        #expect(reconciledState.preparationStateStore.extractedPayloadDirectoryURL(for: option.id) == nil)
    }

    private func downloadableOption() -> HomebrewOption {
        HomebrewOption(
            id: HomebrewOptionID.builtIn(.hackMii),
            name: "HackMii",
            summaryKey: "chooseHomebrew.hackMii.description",
            category: .installers,
            systemImageName: "hammer",
            preparationKind: .downloadable,
            downloadRequest: HomebrewDownloadRequest(
                approvedBaseURL: URL(string: "https://example.com/")!,
                payloadFileName: "hackmii.zip",
                expectedSHA256: "expected-sha"
            ),
            source: .builtIn(.hackMii)
        )
    }

    private func setupRequiredOption() -> HomebrewOption {
        HomebrewOption(
            id: HomebrewOptionID.builtIn(.wilbrand),
            name: "Wilbrand",
            summaryKey: "chooseHomebrew.wilbrand.description",
            category: .exploits,
            systemImageName: "ladybug",
            preparationKind: .setupRequired,
            setupURL: URL(string: "https://example.com/")!,
            source: .builtIn(.wilbrand)
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        return directoryURL
    }
}

private final class RecordingChecksumVerifier: HomebrewPayloadChecksumVerifying {
    private(set) var verifiedPayloadURLs: [URL] = []
    private(set) var expectedSHA256Values: [String?] = []

    func verifyDownloadedPayload(
        at payloadURL: URL,
        expectedSHA256: String?
    ) throws {
        verifiedPayloadURLs.append(payloadURL)
        expectedSHA256Values.append(expectedSHA256)
    }
}

private struct ThrowingChecksumVerifier: HomebrewPayloadChecksumVerifying {
    func verifyDownloadedPayload(
        at payloadURL: URL,
        expectedSHA256: String?
    ) throws {
        throw HomebrewPayloadChecksumError.checksumMismatch(
            expectedSHA256: expectedSHA256 ?? "",
            actualSHA256: "actual-sha"
        )
    }
}
