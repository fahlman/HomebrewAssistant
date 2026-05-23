//
//  HomebrewPayloadDownloadService.swift
//  Homebrew Assistant
//
//  Purpose: Downloads trusted homebrew payload archives into sandboxed
//  Application Support storage.
//  Owns: Payload download protocol, download error model, HTTPS response
//  validation, checksum verification orchestration, and Application Support
//  Downloads staging.
//  Does not own: Checksum implementation, dashboard state, archive extraction,
//  generated archive import, SD card writes, workflow navigation, or view
//  rendering.
//

import Foundation

protocol HomebrewPayloadDownloading {
    func download(
        _ request: HomebrewDownloadRequest,
        progress: @escaping (Double) -> Void
    ) async throws -> URL
}

enum HomebrewDownloadError: Error, Equatable {
    case missingDownloadRequest
    case insecureSourceURL
    case invalidResponse
    case emptyPayload
}

extension HomebrewDownloadError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingDownloadRequest:
            "No approved download request is available."
        case .insecureSourceURL:
            "The download source is not HTTPS."
        case .invalidResponse:
            "The server did not return a successful response."
        case .emptyPayload:
            "The downloaded file was empty."
        }
    }
}

struct URLSessionHomebrewPayloadDownloader: HomebrewPayloadDownloading {
    private let checksumVerifier: any HomebrewPayloadChecksumVerifying
    private let diagnosticsRecorder: (any HomebrewPreparationDiagnosticsRecording)?

    init(
        checksumVerifier: any HomebrewPayloadChecksumVerifying = SHA256HomebrewPayloadChecksumVerifier(),
        diagnosticsRecorder: (any HomebrewPreparationDiagnosticsRecording)? = nil
    ) {
        self.checksumVerifier = checksumVerifier
        self.diagnosticsRecorder = diagnosticsRecorder
    }

    func download(
        _ request: HomebrewDownloadRequest,
        progress: @escaping (Double) -> Void
    ) async throws -> URL {
        progress(0)

        guard request.payloadURL.scheme?.lowercased() == "https" else {
            diagnosticsRecorder?.record(
                action: .httpsValidationFailed,
                message: "Rejected non-HTTPS payload URL \(request.payloadURL.absoluteString)."
            )
            throw HomebrewDownloadError.insecureSourceURL
        }

        diagnosticsRecorder?.record(
            action: .httpsValidationPassed,
            message: "Accepted HTTPS payload URL \(request.payloadURL.absoluteString)."
        )
        diagnosticsRecorder?.record(
            action: .networkRequestStarted,
            message: "Started network request for \(request.payloadFileName)."
        )
        let (temporaryURL, response) = try await URLSession.shared.download(from: request.payloadURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            if let httpResponse = response as? HTTPURLResponse {
                diagnosticsRecorder?.record(
                    action: .serverResponseReceived,
                    message: "Server returned HTTP \(httpResponse.statusCode) for \(request.payloadFileName)."
                )
            }
            throw HomebrewDownloadError.invalidResponse
        }
        diagnosticsRecorder?.record(
            action: .serverResponseReceived,
            message: "Server returned HTTP \(httpResponse.statusCode) for \(request.payloadFileName)."
        )

        let temporaryPayloadURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent(request.payloadFileName)
        let temporaryPayloadDirectory = temporaryPayloadURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: temporaryPayloadDirectory,
            withIntermediateDirectories: true
        )
        try FileManager.default.moveItem(at: temporaryURL, to: temporaryPayloadURL)

        let attributes = try FileManager.default.attributesOfItem(atPath: temporaryPayloadURL.path)
        let payloadByteCount = (attributes[.size] as? NSNumber)?.intValue ?? 0
        guard payloadByteCount > 0 else {
            diagnosticsRecorder?.record(
                action: .emptyPayloadRejected,
                message: "Rejected empty payload for \(request.payloadFileName)."
            )
            throw HomebrewDownloadError.emptyPayload
        }
        diagnosticsRecorder?.record(
            action: .payloadWritten,
            message: "Wrote \(payloadByteCount) bytes to temporary payload \(temporaryPayloadURL.lastPathComponent)."
        )

        diagnosticsRecorder?.record(
            action: .checksumVerificationStarted,
            message: "Started SHA-256 verification for \(request.payloadFileName)."
        )
        do {
            try checksumVerifier.verifyDownloadedPayload(
                at: temporaryPayloadURL,
                expectedSHA256: request.expectedSHA256
            )
        } catch {
            diagnosticsRecorder?.record(
                action: .checksumVerificationFailed,
                message: "SHA-256 verification failed for \(request.payloadFileName): \(error.localizedDescription)"
            )
            throw error
        }
        diagnosticsRecorder?.record(
            action: .checksumVerificationSucceeded,
            message: "SHA-256 verification succeeded for \(request.payloadFileName)."
        )

        let downloadsDirectory = try applicationSupportDownloadsDirectory()
        let destinationURL = downloadsDirectory.appendingPathComponent(
            request.payloadFileName,
            isDirectory: false
        )
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        try FileManager.default.moveItem(at: temporaryPayloadURL, to: destinationURL)
        diagnosticsRecorder?.record(
            action: .payloadStored,
            message: "Stored verified payload in Application Support Downloads as \(destinationURL.lastPathComponent)."
        )

        progress(1)
        return destinationURL
    }

    private func applicationSupportDownloadsDirectory() throws -> URL {
        guard let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw CocoaError(.fileNoSuchFile)
        }

        let downloadsDirectory = applicationSupportDirectory
            .appendingPathComponent("Homebrew Assistant", isDirectory: true)
            .appendingPathComponent("Downloads", isDirectory: true)
        try FileManager.default.createDirectory(
            at: downloadsDirectory,
            withIntermediateDirectories: true
        )
        return downloadsDirectory
    }
}
