//
//  WorkflowSessionControllerTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies active workflow session controller wiring.
//  Covers: Session controller construction and synchronization from SD card
//  readiness into fixed workflow-step completion state.
//  Does not cover: SwiftUI layout, sidebar rendering, bottom button rendering,
//  native scoped access, native disk metadata lookup, downloads, staging, or
//  file writes.
//

import Foundation
import Testing
@testable import Homebrew_Assistant

@MainActor
struct WorkflowSessionControllerTests {
    @Test func sessionCreatesSharedControllers() {
        let sessionController = WorkflowSessionController()

        #expect(sessionController.coordinator.workflowItems == [
            .fixed(.sdCardSelection),
            .fixed(.chooseItems)
        ])
        #expect(sessionController.sdSelectionController.readiness == nil)
        #expect(sessionController.homebrewDashboardController.visibleOptions.map(\.source) == [
            .internalWorkflow(.wilbrand),
            .internalWorkflow(.hackMii)
        ])
    }

    @Test func readySDCardSelectionCompletesFixedSDCardStep() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: readyMetadata(for: volumeURL))

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))

        #expect(sessionController.coordinator.isCompleted(.fixed(.sdCardSelection)))
        #expect(sessionController.coordinator.canSelect(.fixed(.chooseItems)))
    }

    @Test func unavailableSDCardSelectionDoesNotCompleteFixedSDCardStep() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let sessionController = makeSessionController(metadata: unsupportedFilesystemMetadata(for: volumeURL))

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))

        #expect(!sessionController.coordinator.isCompleted(.fixed(.sdCardSelection)))
        #expect(!sessionController.coordinator.canSelect(.fixed(.chooseItems)))
    }

    @Test func changingFromReadyToUnavailableInvalidatesFixedSDCardStep() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let metadataProvider = MutableDiskMetadataProvider(metadata: readyMetadata(for: volumeURL))
        let sessionController = makeSessionController(metadataProvider: metadataProvider)

        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))
        #expect(sessionController.coordinator.isCompleted(.fixed(.sdCardSelection)))

        metadataProvider.metadata = unsupportedFilesystemMetadata(for: volumeURL)
        sessionController.sdSelectionController.handleVolumeSelection(.success([volumeURL]))

        #expect(!sessionController.coordinator.isCompleted(.fixed(.sdCardSelection)))
        #expect(sessionController.coordinator.selectedItemID == WorkflowItem.fixed(.sdCardSelection).id)
    }

    private func makeSessionController(metadata: DiskVolumeMetadata?) -> WorkflowSessionController {
        makeSessionController(metadataProvider: MutableDiskMetadataProvider(metadata: metadata))
    }

    private func makeSessionController(metadataProvider: MutableDiskMetadataProvider) -> WorkflowSessionController {
        let scopedAccessManager = ScopedAccessManager(accessSessionFactory: FakeSecurityScopedAccessSessionFactory())
        let sdCardValidationService = SDCardValidationService(metadataProvider: metadataProvider)
        let sdSelectionController = SDSelectionController(
            scopedAccessManager: scopedAccessManager,
            sdCardValidationService: sdCardValidationService
        )

        return WorkflowSessionController(sdSelectionController: sdSelectionController)
    }

    private func readyMetadata(for volumeURL: URL) -> DiskVolumeMetadata {
        DiskVolumeMetadata(
            volumeURL: volumeURL,
            localizedName: "Test SD",
            protocolName: "Secure Digital",
            fileSystemType: "msdos",
            isWritable: true,
            isRemovable: true,
            isEjectable: true,
            isInternal: false
        )
    }

    private func unsupportedFilesystemMetadata(for volumeURL: URL) -> DiskVolumeMetadata {
        DiskVolumeMetadata(
            volumeURL: volumeURL,
            localizedName: "Test SD",
            protocolName: "Secure Digital",
            fileSystemType: "apfs",
            isWritable: true,
            isRemovable: true,
            isEjectable: true,
            isInternal: false
        )
    }
}

private final class MutableDiskMetadataProvider: DiskMetadataProvider {
    var metadata: DiskVolumeMetadata?

    init(metadata: DiskVolumeMetadata?) {
        self.metadata = metadata
    }

    func metadata(for volumeURL: URL) -> DiskVolumeMetadata? {
        metadata
    }
}

private struct FakeSecurityScopedAccessSessionFactory: SecurityScopedAccessSessionFactory {
    func makeSession(for volumeURL: URL) -> (any SecurityScopedAccessSession)? {
        FakeSecurityScopedAccessSession(volumeURL: volumeURL)
    }
}

private final class FakeSecurityScopedAccessSession: SecurityScopedAccessSession {
    let volumeURL: URL
    private(set) var didStop = false

    init(volumeURL: URL) {
        self.volumeURL = volumeURL
    }

    func stop() {
        didStop = true
    }
}

