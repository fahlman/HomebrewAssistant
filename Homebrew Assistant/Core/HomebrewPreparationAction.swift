//
//  HomebrewPreparationAction.swift
//  Homebrew Assistant
//
//  Purpose: Defines dashboard preparation action intents and execution seams for
//  selected homebrew.
//  Owns: Preparation action identity, bottom-bar button metadata for setup,
//  download, and save intents, executor protocol, default immediate executor,
//  and executor-produced status updates.
//  Does not own: Dashboard action-state derivation, preparation status storage,
//  browser launching, real download execution, verification, staging, SD card
//  writes, or workflow navigation.
//  Used by: HomebrewDashboardController and HomebrewDashboardActionState.
//

import Foundation

enum HomebrewPreparationAction: Equatable {
    case setUp(optionName: String?)
    case chooseGeneratedArchive
    case download
    case extract
    case save

    var titleKey: String {
        switch self {
        case .setUp(let optionName):
            optionName == nil ? "chooseHomebrew.setupSelected.button" : "chooseHomebrew.setupNamed.button"
        case .chooseGeneratedArchive:
            "chooseHomebrew.chooseGeneratedArchive.button"
        case .download:
            "chooseHomebrew.download.button"
        case .extract:
            "chooseHomebrew.extract.button"
        case .save:
            "chooseHomebrew.save.button"
        }
    }

    var titleArguments: [String] {
        switch self {
        case .setUp(let optionName):
            optionName.map { [$0] } ?? []
        case .chooseGeneratedArchive, .download, .extract, .save:
            []
        }
    }

    var systemImageName: String {
        switch self {
        case .setUp:
            "safari"
        case .chooseGeneratedArchive:
            "doc.badge.plus"
        case .download:
            "arrow.down.circle"
        case .extract:
            "archivebox"
        case .save:
            "square.and.arrow.down"
        }
    }
}

struct HomebrewPreparationStatusUpdate: Equatable {
    let optionID: HomebrewOption.ID
    let newStatus: HomebrewPreparationStatus
    let reason: HomebrewPreparationStateTransitionReason
    let preparedPayloadURL: URL?
    let extractedPayloadDirectoryURL: URL?

    init(
        optionID: HomebrewOption.ID,
        newStatus: HomebrewPreparationStatus,
        reason: HomebrewPreparationStateTransitionReason,
        preparedPayloadURL: URL? = nil,
        extractedPayloadDirectoryURL: URL? = nil
    ) {
        self.optionID = optionID
        self.newStatus = newStatus
        self.reason = reason
        self.preparedPayloadURL = preparedPayloadURL
        self.extractedPayloadDirectoryURL = extractedPayloadDirectoryURL
    }
}

@MainActor
protocol HomebrewPreparationExecutor {
    func updates(
        _ action: HomebrewPreparationAction,
        for selectedOptions: [HomebrewOption],
        currentStatus: @escaping (HomebrewOption) -> HomebrewPreparationStatus,
        preparedPayloadURL: @escaping (HomebrewOption) -> URL?
    ) -> AsyncStream<HomebrewPreparationStatusUpdate>
}

struct ImmediateHomebrewPreparationExecutor: HomebrewPreparationExecutor {
    private let payloadDownloader: any HomebrewPayloadDownloading
    private let archiveExtractor: any HomebrewArchiveExtracting
    private let browserOpener: any BrowserOpening
    private let generatedArchiveSelector: any GeneratedArchiveSelecting
    private let generatedArchiveValidator: WilbrandGeneratedArchiveValidator
    private let generatedArchiveStager: ApplicationSupportGeneratedArchiveStager
    private let diagnosticsRecorder: (any HomebrewPreparationDiagnosticsRecording)?

    init(
        payloadDownloader: any HomebrewPayloadDownloading = URLSessionHomebrewPayloadDownloader(),
        archiveExtractor: any HomebrewArchiveExtracting = ZIPFoundationHomebrewArchiveExtractor(),
        browserOpener: any BrowserOpening = AppKitBrowserOpener(),
        generatedArchiveSelector: any GeneratedArchiveSelecting = AppKitGeneratedArchiveSelector(),
        generatedArchiveValidator: WilbrandGeneratedArchiveValidator = WilbrandGeneratedArchiveValidator(),
        generatedArchiveStager: ApplicationSupportGeneratedArchiveStager = ApplicationSupportGeneratedArchiveStager(),
        diagnosticsRecorder: (any HomebrewPreparationDiagnosticsRecording)? = nil
    ) {
        self.payloadDownloader = payloadDownloader
        self.archiveExtractor = archiveExtractor
        self.browserOpener = browserOpener
        self.generatedArchiveSelector = generatedArchiveSelector
        self.generatedArchiveValidator = generatedArchiveValidator
        self.generatedArchiveStager = generatedArchiveStager
        self.diagnosticsRecorder = diagnosticsRecorder
    }

    func updates(
        _ action: HomebrewPreparationAction,
        for selectedOptions: [HomebrewOption],
        currentStatus: @escaping (HomebrewOption) -> HomebrewPreparationStatus,
        preparedPayloadURL: @escaping (HomebrewOption) -> URL?
    ) -> AsyncStream<HomebrewPreparationStatusUpdate> {
        AsyncStream { continuation in
            Task {
                switch action {
                case .setUp:
                    for option in selectedOptions where currentStatus(option) == .setupRequired {
                        if let setupURL = option.setupURL {
                            browserOpener.open(setupURL)
                            diagnosticsRecorder?.record(
                                action: .browserOpened,
                                option: option,
                                message: "Opened browser for \(option.name) at \(setupURL.absoluteString)."
                            )
                            continuation.yield(
                                HomebrewPreparationStatusUpdate(
                                    optionID: option.id,
                                    newStatus: .generatedArchiveRequired,
                                    reason: .browserOpened
                                )
                            )
                        } else {
                            continuation.yield(
                                HomebrewPreparationStatusUpdate(
                                    optionID: option.id,
                                    newStatus: .readyToSave,
                                    reason: .setupCompleted
                                )
                            )
                        }
                    }
                case .chooseGeneratedArchive:
                    for option in selectedOptions where currentStatus(option) == .generatedArchiveRequired {
                        diagnosticsRecorder?.record(
                            action: .generatedArchiveSelectionRequested,
                            option: option,
                            message: "Requested generated archive selection for \(option.name)."
                        )

                        do {
                            guard let selectedArchiveURL = try await generatedArchiveSelector.selectGeneratedArchive(for: option) else {
                                diagnosticsRecorder?.record(
                                    action: .generatedArchiveSelectionCancelled,
                                    option: option,
                                    message: "Generated archive selection was cancelled for \(option.name)."
                                )
                                continuation.yield(
                                    HomebrewPreparationStatusUpdate(
                                        optionID: option.id,
                                        newStatus: .generatedArchiveRequired,
                                        reason: .generatedArchiveImportCancelled
                                    )
                                )
                                continue
                            }

                            diagnosticsRecorder?.record(
                                action: .generatedArchiveSelected,
                                option: option,
                                message: "Selected generated archive \(selectedArchiveURL.lastPathComponent) for \(option.name)."
                            )
                            diagnosticsRecorder?.record(
                                action: .generatedArchiveValidationStarted,
                                option: option,
                                message: "Started generated archive validation for \(option.name)."
                            )
                            do {
                                try generatedArchiveValidator.validateArchive(at: selectedArchiveURL)
                            } catch {
                                diagnosticsRecorder?.record(
                                    action: .generatedArchiveValidationFailed,
                                    option: option,
                                    message: "Generated archive validation failed for \(option.name): \(error.localizedDescription)"
                                )
                                throw error
                            }
                            diagnosticsRecorder?.record(
                                action: .generatedArchiveValidationSucceeded,
                                option: option,
                                message: "Generated archive validation succeeded for \(option.name)."
                            )

                            let stagedArchiveURL = try generatedArchiveStager.stageArchive(
                                at: selectedArchiveURL,
                                for: option
                            )
                            diagnosticsRecorder?.record(
                                action: .generatedArchiveStored,
                                option: option,
                                message: "Stored generated archive for \(option.name) in app staging."
                            )
                            diagnosticsRecorder?.record(
                                action: .extractionStarted,
                                option: option,
                                message: "Extraction started for \(option.name)."
                            )
                            let extractedPayloadDirectoryURL = try await archiveExtractor.extractArchive(
                                at: stagedArchiveURL,
                                for: option
                            )
                            diagnosticsRecorder?.record(
                                action: .extractionCompleted,
                                option: option,
                                message: "Extraction completed for \(option.name)."
                            )

                            continuation.yield(
                                HomebrewPreparationStatusUpdate(
                                    optionID: option.id,
                                    newStatus: .readyToSave,
                                    reason: .generatedArchiveImported,
                                    preparedPayloadURL: stagedArchiveURL,
                                    extractedPayloadDirectoryURL: extractedPayloadDirectoryURL
                                )
                            )
                        } catch {
                            continuation.yield(
                                HomebrewPreparationStatusUpdate(
                                    optionID: option.id,
                                    newStatus: .failed(message: "Generated archive import failed for \(option.name)."),
                                    reason: .generatedArchiveImportFailed
                                )
                            )
                        }
                    }
                case .download:
                    for option in selectedOptions where currentStatus(option) == .readyToDownload {
                        diagnosticsRecorder?.record(
                            action: .downloadRequested,
                            option: option,
                            message: "Download requested for \(option.name)."
                        )
                        continuation.yield(
                            HomebrewPreparationStatusUpdate(
                                optionID: option.id,
                                newStatus: .downloading(progress: 0),
                                reason: .downloadStarted
                            )
                        )

                        guard let downloadRequest = option.downloadRequest else {
                            diagnosticsRecorder?.record(
                                action: .downloadFailed,
                                option: option,
                                message: "Download failed for \(option.name): no approved download request is available."
                            )
                            continuation.yield(
                                HomebrewPreparationStatusUpdate(
                                    optionID: option.id,
                                    newStatus: .failed(message: "No approved download source is available for \(option.name)."),
                                    reason: .downloadFailed
                                )
                            )
                            continue
                        }

                        do {
                            diagnosticsRecorder?.record(
                                action: .payloadURLDerived,
                                option: option,
                                message: "Derived payload URL \(downloadRequest.payloadURL.absoluteString)."
                            )
                            let preparedPayloadURL = try await payloadDownloader.download(downloadRequest) { progress in
                                continuation.yield(
                                    HomebrewPreparationStatusUpdate(
                                        optionID: option.id,
                                        newStatus: .downloading(progress: progress),
                                        reason: .downloadProgressed
                                    )
                                )
                            }
                            diagnosticsRecorder?.record(
                                action: .extractionStarted,
                                option: option,
                                message: "Extraction started for \(option.name)."
                            )
                            let extractedPayloadDirectoryURL = try await archiveExtractor.extractArchive(
                                at: preparedPayloadURL,
                                for: option
                            )
                            diagnosticsRecorder?.record(
                                action: .extractionCompleted,
                                option: option,
                                message: "Extraction completed for \(option.name)."
                            )
                            diagnosticsRecorder?.record(
                                action: .downloadCompleted,
                                option: option,
                                message: "Download completed, verified, and extracted for \(option.name)."
                            )
                            continuation.yield(
                                HomebrewPreparationStatusUpdate(
                                    optionID: option.id,
                                    newStatus: .readyToSave,
                                    reason: .downloadCompleted,
                                    preparedPayloadURL: preparedPayloadURL,
                                    extractedPayloadDirectoryURL: extractedPayloadDirectoryURL
                                )
                            )
                        } catch {
                            diagnosticsRecorder?.record(
                                action: .downloadFailed,
                                option: option,
                                message: "Download failed for \(option.name): \(error.localizedDescription)"
                            )
                            continuation.yield(
                                HomebrewPreparationStatusUpdate(
                                    optionID: option.id,
                                    newStatus: .failed(message: "Download failed for \(option.name)."),
                                    reason: .downloadFailed
                                )
                            )
                        }
                    }
                case .extract:
                    for option in selectedOptions where currentStatus(option) == .readyToExtract {
                        guard let preparedPayloadURL = preparedPayloadURL(option) else {
                            continuation.yield(
                                HomebrewPreparationStatusUpdate(
                                    optionID: option.id,
                                    newStatus: .failed(message: "No prepared archive is available for \(option.name)."),
                                    reason: .extractionFailed
                                )
                            )
                            continue
                        }

                        continuation.yield(
                            HomebrewPreparationStatusUpdate(
                                optionID: option.id,
                                newStatus: .extracting,
                                reason: .extractionStarted
                            )
                        )
                        diagnosticsRecorder?.record(
                            action: .extractionStarted,
                            option: option,
                            message: "Extraction started for \(option.name)."
                        )

                        do {
                            let extractedPayloadDirectoryURL = try await archiveExtractor.extractArchive(
                                at: preparedPayloadURL,
                                for: option
                            )
                            diagnosticsRecorder?.record(
                                action: .extractionCompleted,
                                option: option,
                                message: "Extraction completed for \(option.name)."
                            )
                            continuation.yield(
                                HomebrewPreparationStatusUpdate(
                                    optionID: option.id,
                                    newStatus: .readyToSave,
                                    reason: .extractionCompleted,
                                    extractedPayloadDirectoryURL: extractedPayloadDirectoryURL
                                )
                            )
                        } catch {
                            diagnosticsRecorder?.record(
                                action: .extractionFailed,
                                option: option,
                                message: "Extraction failed for \(option.name): \(error.localizedDescription)"
                            )
                            continuation.yield(
                                HomebrewPreparationStatusUpdate(
                                    optionID: option.id,
                                    newStatus: .failed(message: "Extraction failed for \(option.name)."),
                                    reason: .extractionFailed
                                )
                            )
                        }
                    }
                case .save:
                    for option in selectedOptions where currentStatus(option) == .readyToSave {
                        continuation.yield(
                            HomebrewPreparationStatusUpdate(
                                optionID: option.id,
                                newStatus: .saving(progress: 0),
                                reason: .saveStarted
                            )
                        )
                        continuation.yield(
                            HomebrewPreparationStatusUpdate(
                                optionID: option.id,
                                newStatus: .saved,
                                reason: .saveCompleted
                            )
                        )
                    }
                }

                continuation.finish()
            }
        }
    }
}
