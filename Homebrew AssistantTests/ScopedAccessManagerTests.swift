//
//  ScopedAccessManagerTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies scoped-access session state behavior.
//  Covers: Initial state, failed access attempts, successful access attempts,
//  reset behavior, and replacing an active access session.
//  Does not cover: Native security-scoped resource APIs, user file pickers,
//  SD card readiness validation, workflow navigation, or filesystem writes.
//

import Foundation
import Testing
@testable import Homebrew_Assistant

@MainActor
struct ScopedAccessManagerTests {
    @Test func initialStateHasNoSelectedVolumeAndNoActiveAccess() {
        let manager = ScopedAccessManager(accessSessionFactory: FakeAccessSessionFactory())

        #expect(manager.selectedVolumeURL == nil)
        #expect(manager.isAccessingSelectedVolume == false)
    }

    @Test func failedAccessLeavesStateCleared() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let factory = FakeAccessSessionFactory(shouldCreateSession: false)
        let manager = ScopedAccessManager(accessSessionFactory: factory)

        let didStartAccess = manager.startAccessing(volumeURL)

        #expect(didStartAccess == false)
        #expect(manager.selectedVolumeURL == nil)
        #expect(manager.isAccessingSelectedVolume == false)
    }

    @Test func successfulAccessStoresSelectedVolumeAndMarksAccessActive() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let factory = FakeAccessSessionFactory()
        let manager = ScopedAccessManager(accessSessionFactory: factory)

        let didStartAccess = manager.startAccessing(volumeURL)

        #expect(didStartAccess == true)
        #expect(manager.selectedVolumeURL == volumeURL)
        #expect(manager.isAccessingSelectedVolume == true)
        #expect(factory.createdSessions.count == 1)
        #expect(factory.createdSessions.first?.volumeURL == volumeURL)
    }

    @Test func resetStopsActiveSessionAndClearsState() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let factory = FakeAccessSessionFactory()
        let manager = ScopedAccessManager(accessSessionFactory: factory)

        _ = manager.startAccessing(volumeURL)
        manager.reset()

        #expect(manager.selectedVolumeURL == nil)
        #expect(manager.isAccessingSelectedVolume == false)
        #expect(factory.createdSessions.first?.stopCallCount == 1)
    }

    @Test func startingNewAccessStopsPreviousSessionAndTracksNewVolume() {
        let firstURL = URL(fileURLWithPath: "/Volumes/FirstSD")
        let secondURL = URL(fileURLWithPath: "/Volumes/SecondSD")
        let factory = FakeAccessSessionFactory()
        let manager = ScopedAccessManager(accessSessionFactory: factory)

        _ = manager.startAccessing(firstURL)
        _ = manager.startAccessing(secondURL)

        #expect(manager.selectedVolumeURL == secondURL)
        #expect(manager.isAccessingSelectedVolume == true)
        #expect(factory.createdSessions.count == 2)
        #expect(factory.createdSessions[0].stopCallCount == 1)
        #expect(factory.createdSessions[1].stopCallCount == 0)
    }
}

private final class FakeAccessSessionFactory: SecurityScopedAccessSessionFactory {
    let shouldCreateSession: Bool
    private(set) var createdSessions: [FakeAccessSession] = []

    init(shouldCreateSession: Bool = true) {
        self.shouldCreateSession = shouldCreateSession
    }

    func makeSession(for volumeURL: URL) -> (any SecurityScopedAccessSession)? {
        guard shouldCreateSession else { return nil }

        let session = FakeAccessSession(volumeURL: volumeURL)
        createdSessions.append(session)
        return session
    }
}

private final class FakeAccessSession: SecurityScopedAccessSession {
    let volumeURL: URL
    private(set) var stopCallCount = 0

    init(volumeURL: URL) {
        self.volumeURL = volumeURL
    }

    func stop() {
        stopCallCount += 1
    }
}
