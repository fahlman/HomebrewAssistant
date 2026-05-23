//
//  HomebrewPreparationReconciler.swift
//  Homebrew Assistant
//
//  Purpose: Restores in-memory homebrew preparation state from sandboxed
//  Application Support staging files.
//  Owns: Startup reconciliation of trusted staged archives, extracted payload
//  directories, and selected option IDs derived from restorable preparation.
//  Does not own: Dashboard UI, active downloads, archive extraction, SD card
//  writes, or persistent user preferences.
//

import Foundation

struct ReconciledHomebrewPreparationState {
    let selectedOptionIDs: Set<HomebrewOption.ID>
    let preparationStateStore: HomebrewPreparationStateStore
    let cleanupActions: [HomebrewPreparationCleanupAction]

    init(
        selectedOptionIDs: Set<HomebrewOption.ID>,
        preparationStateStore: HomebrewPreparationStateStore,
        cleanupActions: [HomebrewPreparationCleanupAction] = []
    ) {
        self.selectedOptionIDs = selectedOptionIDs
        self.preparationStateStore = preparationStateStore
        self.cleanupActions = cleanupActions
    }
}

nonisolated enum HomebrewPreparationCleanupAction: Equatable, Sendable {
    case removeStaleExtraction(optionID: HomebrewOption.ID, url: URL)
}

extension HomebrewPreparationCleanupAction {
    func apply() {
        switch self {
        case .removeStaleExtraction(_, let url):
            guard isExistingDirectory(at: url) else {
                return
            }

            try? FileManager.default.removeItem(at: url)
        }
    }

    private func isExistingDirectory(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        ) && isDirectory.boolValue
    }
}

protocol HomebrewPreparationStateReconciling {
    func reconciledState(for options: [HomebrewOption]) -> ReconciledHomebrewPreparationState
}

struct ApplicationSupportHomebrewPreparationReconciler: HomebrewPreparationStateReconciling {
    private let checksumVerifier: any HomebrewPayloadChecksumVerifying
    private let generatedArchiveValidator: WilbrandGeneratedArchiveValidator
    private let applicationSupportDirectory: URL?

    init(
        checksumVerifier: any HomebrewPayloadChecksumVerifying = SHA256HomebrewPayloadChecksumVerifier(),
        generatedArchiveValidator: WilbrandGeneratedArchiveValidator = WilbrandGeneratedArchiveValidator(),
        applicationSupportDirectory: URL? = nil
    ) {
        self.checksumVerifier = checksumVerifier
        self.generatedArchiveValidator = generatedArchiveValidator
        self.applicationSupportDirectory = applicationSupportDirectory
    }

    func reconciledState(for options: [HomebrewOption]) -> ReconciledHomebrewPreparationState {
        var selectedOptionIDs: Set<HomebrewOption.ID> = []
        var preparationStateStore = HomebrewPreparationStateStore()
        var cleanupActions: [HomebrewPreparationCleanupAction] = []

        for option in options {
            let reconciledOption = reconciledOptionState(for: option)
            cleanupActions.append(contentsOf: reconciledOption.cleanupActions)

            guard let preparedState = reconciledOption.restorablePreparedState else {
                continue
            }

            selectedOptionIDs.insert(option.id)
            preparationStateStore[option.id] = preparedState.extractedPayloadDirectoryURL == nil
                ? .readyToExtract
                : .readyToSave
            preparationStateStore.setPreparedPayloadURL(
                preparedState.preparedPayloadURL,
                for: option.id
            )
            if let extractedPayloadDirectoryURL = preparedState.extractedPayloadDirectoryURL {
                preparationStateStore.setExtractedPayloadDirectoryURL(
                    extractedPayloadDirectoryURL,
                    for: option.id
                )
            }
        }

        return ReconciledHomebrewPreparationState(
            selectedOptionIDs: selectedOptionIDs,
            preparationStateStore: preparationStateStore,
            cleanupActions: cleanupActions
        )
    }

    private func reconciledOptionState(for option: HomebrewOption) -> ReconciledOptionPreparationState {
        let extractedPayloadDirectoryURL = extractedPayloadDirectory(for: option)
        guard let preparedPayloadURL = preparedPayloadURL(for: option),
              FileManager.default.fileExists(atPath: preparedPayloadURL.path),
              isRestorablePreparedPayload(preparedPayloadURL, for: option)
        else {
            return ReconciledOptionPreparationState(
                restorablePreparedState: nil,
                cleanupActions: staleExtractionCleanupActions(
                    for: option,
                    extractedPayloadDirectoryURL: extractedPayloadDirectoryURL
                )
            )
        }

        guard isExistingDirectory(at: extractedPayloadDirectoryURL),
              isDirectoryNonEmpty(at: extractedPayloadDirectoryURL)
        else {
            return ReconciledOptionPreparationState(
                restorablePreparedState: RestorablePreparedState(
                    preparedPayloadURL: preparedPayloadURL,
                    extractedPayloadDirectoryURL: nil
                )
            )
        }

        return ReconciledOptionPreparationState(
            restorablePreparedState: RestorablePreparedState(
                preparedPayloadURL: preparedPayloadURL,
                extractedPayloadDirectoryURL: extractedPayloadDirectoryURL
            )
        )
    }

    private func isRestorablePreparedPayload(
        _ preparedPayloadURL: URL,
        for option: HomebrewOption
    ) -> Bool {
        switch option.preparationKind {
        case .downloadable:
            guard let downloadRequest = option.downloadRequest else {
                return false
            }

            do {
                try checksumVerifier.verifyDownloadedPayload(
                    at: preparedPayloadURL,
                    expectedSHA256: downloadRequest.expectedSHA256
                )
                return true
            } catch {
                return false
            }
        case .setupRequired:
            do {
                try generatedArchiveValidator.validateArchive(at: preparedPayloadURL)
                return true
            } catch {
                return false
            }
        }
    }

    private func preparedPayloadURL(for option: HomebrewOption) -> URL? {
        switch option.preparationKind {
        case .downloadable:
            guard let payloadFileName = option.downloadRequest?.payloadFileName else {
                return nil
            }

            return downloadsDirectory()
                .appendingPathComponent(payloadFileName, isDirectory: false)
        case .setupRequired:
            return importedDirectory()
                .appendingPathComponent(safeFileName(for: option.id, extension: "zip"), isDirectory: false)
        }
    }

    private func extractedPayloadDirectory(for option: HomebrewOption) -> URL {
        applicationSupportHomebrewDirectory()
            .appendingPathComponent("Extracted", isDirectory: true)
            .appendingPathComponent(safeName(for: option.id), isDirectory: true)
    }

    private func downloadsDirectory() -> URL {
        applicationSupportHomebrewDirectory()
            .appendingPathComponent("Downloads", isDirectory: true)
    }

    private func importedDirectory() -> URL {
        applicationSupportHomebrewDirectory()
            .appendingPathComponent("Imported", isDirectory: true)
    }

    private func applicationSupportHomebrewDirectory() -> URL {
        let applicationSupportDirectory = applicationSupportDirectory
            ?? FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
            ?? FileManager.default.temporaryDirectory

        return applicationSupportDirectory
            .appendingPathComponent("Homebrew Assistant", isDirectory: true)
    }

    private func isExistingDirectory(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        ) && isDirectory.boolValue
    }

    private func isDirectoryNonEmpty(at url: URL) -> Bool {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil
        ) else {
            return false
        }

        return !contents.isEmpty
    }

    private func staleExtractionCleanupActions(
        for option: HomebrewOption,
        extractedPayloadDirectoryURL: URL
    ) -> [HomebrewPreparationCleanupAction] {
        guard isExistingDirectory(at: extractedPayloadDirectoryURL) else {
            return []
        }

        return [
            .removeStaleExtraction(
                optionID: option.id,
                url: extractedPayloadDirectoryURL
            )
        ]
    }

    private func safeFileName(for optionID: HomebrewOption.ID, extension pathExtension: String) -> String {
        "\(safeName(for: optionID)).\(pathExtension)"
    }

    private func safeName(for optionID: HomebrewOption.ID) -> String {
        optionID.rawValue.map { character in
            character.isLetter || character.isNumber || character == "-" || character == "_"
                ? character
                : "-"
        }.reduce(into: "") { result, character in
            result.append(character)
        }
    }
}

private struct ReconciledOptionPreparationState {
    let restorablePreparedState: RestorablePreparedState?
    let cleanupActions: [HomebrewPreparationCleanupAction]

    init(
        restorablePreparedState: RestorablePreparedState?,
        cleanupActions: [HomebrewPreparationCleanupAction] = []
    ) {
        self.restorablePreparedState = restorablePreparedState
        self.cleanupActions = cleanupActions
    }
}

private struct RestorablePreparedState {
    let preparedPayloadURL: URL
    let extractedPayloadDirectoryURL: URL?
}
