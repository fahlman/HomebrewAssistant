//
//  SDSelectionControllerTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies SD card selection controller state and bottom-bar policy.
//  Covers: Action-state mapping, default picker action, unsupported-filesystem Disk Utility action,
//  ready-card Next default behavior, clear/reset state, and picker presentation.
//  Does not cover: SwiftUI rendering, native security-scoped access, native disk
//  metadata lookup, Disk Utility process behavior, downloads, staging, or writes.
//

import Foundation
import Testing
@testable import Homebrew_Assistant

@MainActor
struct SDSelectionControllerTests {
    @Test func defaultBottomBarActionChoosesSDCard() {
        let controller = makeController(metadata: nil)

        #expect(controller.actionState == .needsSelection)
        #expect(controller.bottomBarConfiguration.contextualActions.map(\.titleKey) == [
            "sdSelection.chooseSDCard.button"
        ])
        #expect(controller.bottomBarConfiguration.contextualActions.map(\.systemImageName) == [
            "sdcard"
        ])
        #expect(controller.bottomBarConfiguration.defaultAction == .contextualAction(index: 0))
    }

    @Test func chooseSDCardActionPresentsVolumeImporter() {
        let controller = makeController(metadata: nil)
        let chooseAction = controller.bottomBarConfiguration.contextualActions.first

        #expect(chooseAction != nil)
        chooseAction?.perform()

        #expect(controller.isVolumeImporterPresented)
    }

    @Test func unsupportedFilesystemOffersDiskUtilityBeforeChooseSDCard() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let controller = makeController(metadata: unsupportedFilesystemMetadata(for: volumeURL))

        controller.handleVolumeSelection(.success([volumeURL]))

        #expect(controller.actionState == .unsupportedFilesystem(hasOpenedDiskUtility: false))
        #expect(controller.bottomBarConfiguration.contextualActions.map(\.titleKey) == [
            "sdSelection.openDiskUtility.button",
            "sdSelection.chooseSDCard.button"
        ])
        #expect(controller.bottomBarConfiguration.contextualActions.map(\.systemImageName) == [
            "externaldrive.badge.gearshape",
            "sdcard"
        ])
        #expect(controller.bottomBarConfiguration.defaultAction == .contextualAction(index: 0))
    }

    @Test func openedDiskUtilityUnsupportedFilesystemDefaultsBackToChooseSDCard() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let diskUtilityOpener = FakeDiskUtilityOpener()
        let controller = makeController(
            metadata: unsupportedFilesystemMetadata(for: volumeURL),
            diskUtilityOpener: diskUtilityOpener
        )

        controller.handleVolumeSelection(.success([volumeURL]))
        controller.openDiskUtility()

        #expect(diskUtilityOpener.didOpenDiskUtility)
        #expect(controller.actionState == .unsupportedFilesystem(hasOpenedDiskUtility: true))
        #expect(controller.bottomBarConfiguration.contextualActions.map(\.titleKey) == [
            "sdSelection.openDiskUtility.button",
            "sdSelection.chooseSDCard.button"
        ])
        #expect(controller.bottomBarConfiguration.defaultAction == .contextualAction(index: 1))
    }

    @Test func readySDCardMakesNextTheDefaultAction() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let controller = makeController(metadata: readyMetadata(for: volumeURL))

        controller.handleVolumeSelection(.success([volumeURL]))

        #expect(controller.actionState == .ready)
        #expect(controller.readiness?.isReady == true)
        #expect(controller.bottomBarConfiguration.contextualActions.map(\.titleKey) == [
            "sdSelection.chooseSDCard.button"
        ])
        #expect(controller.bottomBarConfiguration.defaultAction == .next)
    }

    @Test func clearSelectionClearsReadinessDriveErrorAndDiskUtilityTracking() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let controller = makeController(metadata: unsupportedFilesystemMetadata(for: volumeURL))

        controller.handleVolumeSelection(.success([volumeURL]))
        controller.clearSelection()

        #expect(controller.readiness == nil)
        #expect(controller.selectedDrive == nil)
        #expect(controller.selectionErrorMessage == nil)
        #expect(!controller.hasOpenedDiskUtilityForCurrentSelection)
        #expect(controller.actionState == .needsSelection)
        #expect(controller.bottomBarConfiguration.contextualActions.map(\.titleKey) == [
            "sdSelection.chooseSDCard.button"
        ])
    }

    @Test func resetClearsSelectionAndDismissesVolumeImporter() {
        let controller = makeController(metadata: nil)

        controller.presentVolumeImporter()
        controller.reset()

        #expect(!controller.isVolumeImporterPresented)
        #expect(controller.readiness == nil)
        #expect(controller.selectedDrive == nil)
        #expect(controller.selectionErrorMessage == nil)
        #expect(controller.actionState == .needsSelection)
    }

    private func makeController(
        metadata: DiskVolumeMetadata?,
        diskUtilityOpener: any DiskUtilityOpening = FakeDiskUtilityOpener()
    ) -> SDSelectionController {
        SDSelectionController(
            scopedAccessManager: ScopedAccessManager(accessSessionFactory: FakeSecurityScopedAccessSessionFactory()),
            sdCardValidationService: SDCardValidationService(
                metadataProvider: MutableDiskMetadataProvider(metadata: metadata)
            ),
            diskUtilityOpener: diskUtilityOpener
        )
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

private final class FakeDiskUtilityOpener: DiskUtilityOpening {
    private(set) var didOpenDiskUtility = false

    func openDiskUtility() {
        didOpenDiskUtility = true
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
