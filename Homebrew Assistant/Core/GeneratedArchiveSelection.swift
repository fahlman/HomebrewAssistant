//
//  GeneratedArchiveSelection.swift
//  Homebrew Assistant
//
//  Purpose: Defines controlled user selection and staging for browser-generated
//  homebrew ZIP archives.
//  Owns: ZIP file picker boundary, Wilbrand archive shape validation, and
//  sandboxed archive staging.
//  Does not own: Dashboard selection state, archive extraction, SD card writes,
//  workflow navigation, or view rendering.
//  Used by: HomebrewPreparationExecutor.
//

import AppKit
import Foundation
import UniformTypeIdentifiers
import ZIPFoundation

protocol GeneratedArchiveSelecting {
    func selectGeneratedArchive(for option: HomebrewOption) async throws -> URL?
}

struct AppKitGeneratedArchiveSelector: GeneratedArchiveSelecting {
    func selectGeneratedArchive(for option: HomebrewOption) async throws -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.zip]
        panel.prompt = String(localized: "chooseHomebrew.chooseGeneratedArchive.button")
        panel.message = String(localized: "chooseHomebrew.chooseGeneratedArchive.panelMessage")
        panel.directoryURL = FileManager.default.urls(
            for: .downloadsDirectory,
            in: .userDomainMask
        ).first

        let response = panel.runModal()
        guard response == .OK else {
            return nil
        }

        return panel.url
    }
}

struct WilbrandGeneratedArchiveValidator {
    func validateArchive(at archiveURL: URL) throws {
        let archive = try Archive(url: archiveURL, accessMode: .read)
        var normalizedPaths: Set<String> = []

        for entry in archive {
            try validateEntry(entry)
            normalizedPaths.insert(entry.path.lowercased())
        }

        guard normalizedPaths.contains(where: { path in
            path.hasPrefix("private/wii/title/")
        }) else {
            throw GeneratedArchiveImportError.missingWilbrandPrivateTree
        }
    }

    private func validateEntry(_ entry: Entry) throws {
        guard entry.type != .symlink else {
            throw GeneratedArchiveImportError.unsafeArchiveEntry(entry.path)
        }

        let path = entry.path
        guard !path.isEmpty,
              !path.hasPrefix("/"),
              !path.hasPrefix("\\"),
              !path.contains("\\")
        else {
            throw GeneratedArchiveImportError.unsafeArchiveEntry(path)
        }

        let components = path.split(separator: "/", omittingEmptySubsequences: true)
        guard !components.isEmpty else {
            throw GeneratedArchiveImportError.unsafeArchiveEntry(path)
        }

        for component in components {
            guard component != ".", component != ".." else {
                throw GeneratedArchiveImportError.unsafeArchiveEntry(path)
            }
        }
    }
}

struct ApplicationSupportGeneratedArchiveStager {
    func stageArchive(
        at archiveURL: URL,
        for option: HomebrewOption
    ) throws -> URL {
        let directoryURL = try stagingDirectory()
        let destinationURL = directoryURL.appendingPathComponent(
            safeArchiveFileName(for: option),
            isDirectory: false
        )

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: archiveURL, to: destinationURL)
        return destinationURL
    }

    private func stagingDirectory() throws -> URL {
        guard let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw CocoaError(.fileNoSuchFile)
        }

        let directoryURL = applicationSupportDirectory
            .appendingPathComponent("Homebrew Assistant", isDirectory: true)
            .appendingPathComponent("Imported", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        return directoryURL
    }

    private func safeArchiveFileName(for option: HomebrewOption) -> String {
        let safeOptionID = option.id.rawValue.map { character in
            character.isLetter || character.isNumber || character == "-" || character == "_"
                ? character
                : "-"
        }.reduce(into: "") { result, character in
            result.append(character)
        }

        return "\(safeOptionID).zip"
    }
}

enum GeneratedArchiveImportError: Error, Equatable {
    case unsafeArchiveEntry(String)
    case missingWilbrandPrivateTree
}

extension GeneratedArchiveImportError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unsafeArchiveEntry:
            "The selected ZIP contains an unsafe archive entry."
        case .missingWilbrandPrivateTree:
            "The selected ZIP does not contain the expected Wilbrand private/wii/title folder."
        }
    }
}
