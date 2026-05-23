//
//  HomebrewPayloadChecksumVerifier.swift
//  Homebrew Assistant
//
//  Purpose: Verifies downloaded or staged homebrew payload checksums.
//  Owns: Payload checksum verification protocol, SHA-256 implementation, and
//  checksum-specific error cases.
//  Does not own: Network downloads, Application Support staging, archive
//  extraction, dashboard state, SD card writes, or workflow navigation.
//

import CryptoKit
import Foundation

enum HomebrewPayloadChecksumError: Error, Equatable {
    case missingExpectedSHA256
    case invalidExpectedSHA256
    case checksumMismatch(expectedSHA256: String, actualSHA256: String)
}

extension HomebrewPayloadChecksumError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingExpectedSHA256:
            "No expected SHA-256 checksum is available."
        case .invalidExpectedSHA256:
            "The expected SHA-256 checksum is invalid."
        case .checksumMismatch:
            "The downloaded file did not match the expected SHA-256 checksum."
        }
    }
}

protocol HomebrewPayloadChecksumVerifying {
    func verifyDownloadedPayload(
        at payloadURL: URL,
        expectedSHA256: String?
    ) throws
}

struct SHA256HomebrewPayloadChecksumVerifier: HomebrewPayloadChecksumVerifying {
    func verifyDownloadedPayload(
        at payloadURL: URL,
        expectedSHA256: String?
    ) throws {
        guard let expectedSHA256 else {
            throw HomebrewPayloadChecksumError.missingExpectedSHA256
        }

        let normalizedExpectedSHA256 = expectedSHA256
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard normalizedExpectedSHA256.count == 64,
              normalizedExpectedSHA256.allSatisfy(\.isHexDigit)
        else {
            throw HomebrewPayloadChecksumError.invalidExpectedSHA256
        }

        let payloadData = try Data(contentsOf: payloadURL)
        let actualSHA256 = SHA256.hash(data: payloadData)
            .map { String(format: "%02x", $0) }
            .joined()
        guard actualSHA256 == normalizedExpectedSHA256 else {
            throw HomebrewPayloadChecksumError.checksumMismatch(
                expectedSHA256: normalizedExpectedSHA256,
                actualSHA256: actualSHA256
            )
        }
    }
}
