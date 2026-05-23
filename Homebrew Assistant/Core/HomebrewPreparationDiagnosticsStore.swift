//
//  HomebrewPreparationDiagnosticsStore.swift
//  Homebrew Assistant
//
//  Created by Ryan Fahlsing on 5/18/26.
//

import Combine
import Foundation
import OSLog

nonisolated struct HomebrewPreparationDiagnosticEvent: Equatable, Sendable {
    let date: Date
    let optionID: HomebrewOption.ID?
    let optionName: String?
    let action: HomebrewPreparationDiagnosticAction
    let message: String
}

nonisolated enum HomebrewPreparationDiagnosticAction: Equatable, Sendable {
    case downloadRequested
    case browserOpened
    case generatedArchiveSelectionRequested
    case generatedArchiveSelectionCancelled
    case generatedArchiveSelected
    case generatedArchiveValidationStarted
    case generatedArchiveValidationSucceeded
    case generatedArchiveValidationFailed
    case generatedArchiveStored
    case payloadURLDerived
    case httpsValidationPassed
    case httpsValidationFailed
    case networkRequestStarted
    case serverResponseReceived
    case payloadWritten
    case payloadStored
    case emptyPayloadRejected
    case checksumVerificationStarted
    case checksumVerificationSucceeded
    case checksumVerificationFailed
    case extractionStarted
    case extractionDirectoryPrepared
    case extractionCompleted
    case extractionFailed
    case downloadCompleted
    case downloadFailed
}

@MainActor
protocol HomebrewPreparationDiagnosticsRecording: AnyObject {
    func record(_ event: HomebrewPreparationDiagnosticEvent)
}

@MainActor
final class HomebrewPreparationDiagnosticsStore: ObservableObject, HomebrewPreparationDiagnosticsRecording {
    @Published private(set) var events: [HomebrewPreparationDiagnosticEvent]

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "HomebrewAssistant",
        category: "HomebrewPreparation"
    )

    init(events: [HomebrewPreparationDiagnosticEvent] = []) {
        self.events = events
    }

    func record(_ event: HomebrewPreparationDiagnosticEvent) {
        events.append(event)
        logger.info("\(event.action.logName, privacy: .public): \(event.message, privacy: .public)")
    }
}

extension HomebrewPreparationDiagnosticsRecording {
    func record(
        action: HomebrewPreparationDiagnosticAction,
        option: HomebrewOption? = nil,
        message: String,
        date: Date = Date()
    ) {
        record(
            HomebrewPreparationDiagnosticEvent(
                date: date,
                optionID: option?.id,
                optionName: option?.name,
                action: action,
                message: message
            )
        )
    }
}

private extension HomebrewPreparationDiagnosticAction {
    var logName: String {
        switch self {
        case .downloadRequested:
            "downloadRequested"
        case .browserOpened:
            "browserOpened"
        case .generatedArchiveSelectionRequested:
            "generatedArchiveSelectionRequested"
        case .generatedArchiveSelectionCancelled:
            "generatedArchiveSelectionCancelled"
        case .generatedArchiveSelected:
            "generatedArchiveSelected"
        case .generatedArchiveValidationStarted:
            "generatedArchiveValidationStarted"
        case .generatedArchiveValidationSucceeded:
            "generatedArchiveValidationSucceeded"
        case .generatedArchiveValidationFailed:
            "generatedArchiveValidationFailed"
        case .generatedArchiveStored:
            "generatedArchiveStored"
        case .payloadURLDerived:
            "payloadURLDerived"
        case .httpsValidationPassed:
            "httpsValidationPassed"
        case .httpsValidationFailed:
            "httpsValidationFailed"
        case .networkRequestStarted:
            "networkRequestStarted"
        case .serverResponseReceived:
            "serverResponseReceived"
        case .payloadWritten:
            "payloadWritten"
        case .payloadStored:
            "payloadStored"
        case .emptyPayloadRejected:
            "emptyPayloadRejected"
        case .checksumVerificationStarted:
            "checksumVerificationStarted"
        case .checksumVerificationSucceeded:
            "checksumVerificationSucceeded"
        case .checksumVerificationFailed:
            "checksumVerificationFailed"
        case .extractionStarted:
            "extractionStarted"
        case .extractionDirectoryPrepared:
            "extractionDirectoryPrepared"
        case .extractionCompleted:
            "extractionCompleted"
        case .extractionFailed:
            "extractionFailed"
        case .downloadCompleted:
            "downloadCompleted"
        case .downloadFailed:
            "downloadFailed"
        }
    }
}
