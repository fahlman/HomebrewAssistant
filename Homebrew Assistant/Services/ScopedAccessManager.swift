//
//  ScopedAccessManager.swift
//  Homebrew Assistant
//
//  Purpose: Manages security-scoped filesystem access for the user-selected SD card volume.
//  Owns: Starting scoped access, stopping scoped access, active scoped-access
//  tracking, selected-volume URL tracking, session cleanup for scoped access,
//  and injectable scoped-access session creation.
//  Does not own: SD card validation, native volume metadata resolution,
//  file copying, archive extraction, staging, or workflow navigation.
//  Delegates to: SecurityScopedAccessSessionFactory for creating scoped access sessions.
//

import Foundation
import Combine

@MainActor
final class ScopedAccessManager: ObservableObject {
    @Published private(set) var selectedVolumeURL: URL?
    @Published private(set) var isAccessingSelectedVolume = false

    private let accessSessionFactory: any SecurityScopedAccessSessionFactory
    private var accessSession: (any SecurityScopedAccessSession)?

    init() {
        self.accessSessionFactory = ProductionSecurityScopedAccessSessionFactory()
    }

    init(accessSessionFactory: any SecurityScopedAccessSessionFactory) {
        self.accessSessionFactory = accessSessionFactory
    }

    func startAccessing(_ volumeURL: URL) -> Bool {
        stopAccessingSelectedVolume()

        guard let session = accessSessionFactory.makeSession(for: volumeURL) else {
            selectedVolumeURL = nil
            isAccessingSelectedVolume = false
            return false
        }

        accessSession = session
        selectedVolumeURL = volumeURL
        isAccessingSelectedVolume = true
        return true
    }

    func stopAccessingSelectedVolume() {
        accessSession?.stop()
        accessSession = nil
        selectedVolumeURL = nil
        isAccessingSelectedVolume = false
    }

    func reset() {
        stopAccessingSelectedVolume()
    }
}

protocol SecurityScopedAccessSessionFactory {
    func makeSession(for volumeURL: URL) -> (any SecurityScopedAccessSession)?
}

protocol SecurityScopedAccessSession: AnyObject {
    var volumeURL: URL { get }
    func stop()
}

private struct ProductionSecurityScopedAccessSessionFactory: SecurityScopedAccessSessionFactory {
    func makeSession(for volumeURL: URL) -> (any SecurityScopedAccessSession)? {
        ProductionSecurityScopedAccessSession(volumeURL: volumeURL)
    }
}

private final class ProductionSecurityScopedAccessSession: SecurityScopedAccessSession {
    let volumeURL: URL
    private var isActive = false

    init?(volumeURL: URL) {
        guard volumeURL.startAccessingSecurityScopedResource() else {
            return nil
        }

        self.volumeURL = volumeURL
        self.isActive = true
    }

    func stop() {
        guard isActive else { return }

        volumeURL.stopAccessingSecurityScopedResource()
        isActive = false
    }

    deinit {
        stop()
    }
}
