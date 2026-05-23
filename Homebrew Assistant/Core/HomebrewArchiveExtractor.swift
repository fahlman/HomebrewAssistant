//
//  HomebrewArchiveExtractor.swift
//  Homebrew Assistant
//
//  Purpose: Extracts prepared homebrew payload archives into sandboxed
//  Application Support staging directories.
//  Owns: Archive extraction protocol, ZIPFoundation-backed extraction, and
//  extracted payload directory naming.
//  Does not own: Payload downloads, generated archive selection, dashboard
//  state, SD card writes, workflow navigation, or view rendering.
//

import Foundation
import ZIPFoundation

protocol HomebrewArchiveExtracting {
    func extractArchive(
        at archiveURL: URL,
        for option: HomebrewOption
    ) async throws -> URL
}

struct ZIPFoundationHomebrewArchiveExtractor: HomebrewArchiveExtracting {
    private let diagnosticsRecorder: (any HomebrewPreparationDiagnosticsRecording)?

    init(diagnosticsRecorder: (any HomebrewPreparationDiagnosticsRecording)? = nil) {
        self.diagnosticsRecorder = diagnosticsRecorder
    }

    func extractArchive(
        at archiveURL: URL,
        for option: HomebrewOption
    ) async throws -> URL {
        let extractionDirectoryURL = try extractionDirectory(for: option)
        if FileManager.default.fileExists(atPath: extractionDirectoryURL.path) {
            try FileManager.default.removeItem(at: extractionDirectoryURL)
        }
        try FileManager.default.createDirectory(
            at: extractionDirectoryURL,
            withIntermediateDirectories: true
        )
        diagnosticsRecorder?.record(
            action: .extractionDirectoryPrepared,
            option: option,
            message: "Prepared extraction directory for \(option.name)."
        )

        do {
            try await unzip(
                archiveURL: archiveURL,
                extractionDirectoryURL: extractionDirectoryURL
            )
        } catch {
            diagnosticsRecorder?.record(
                action: .extractionFailed,
                option: option,
                message: "Extraction failed for \(option.name): \(error.localizedDescription)"
            )
            throw error
        }

        return extractionDirectoryURL
    }

    private func extractionDirectory(for option: HomebrewOption) throws -> URL {
        guard let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw CocoaError(.fileNoSuchFile)
        }

        return applicationSupportDirectory
            .appendingPathComponent("Homebrew Assistant", isDirectory: true)
            .appendingPathComponent("Extracted", isDirectory: true)
            .appendingPathComponent(safeDirectoryName(for: option.id), isDirectory: true)
    }

    private func safeDirectoryName(for optionID: HomebrewOption.ID) -> String {
        optionID.rawValue.map { character in
            character.isLetter || character.isNumber || character == "-" || character == "_"
                ? character
                : "-"
        }.reduce(into: "") { result, character in
            result.append(character)
        }
    }

    private func unzip(
        archiveURL: URL,
        extractionDirectoryURL: URL
    ) async throws {
        try await Task.detached {
            try FileManager.default.unzipItem(
                at: archiveURL,
                to: extractionDirectoryURL
            )
        }.value
    }
}
