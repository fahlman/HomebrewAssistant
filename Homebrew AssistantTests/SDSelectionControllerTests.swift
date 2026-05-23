//
//  SDSelectionControllerTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies SD card selection controller state and bottom-bar policy.
//  Covers: Action-state mapping, bottom-bar mapping, default picker action, unsupported-filesystem Disk Utility action,
//  ready-card Next default behavior, clear/reset state, and picker presentation.
//  Does not cover: SwiftUI rendering, native security-scoped access, native disk
//  metadata lookup, Disk Utility process behavior, downloads, staging, or writes.
//

import Foundation
import Testing
@testable import Homebrew_Assistant

@MainActor
struct SDSelectionControllerTests {
    @Test func defaultActionStateNeedsSelection() {
        let controller = makeController(metadata: nil)

        #expect(controller.actionState == .needsSelection)
    }

    @Test func needsSelectionBottomBarUsesChooseSDCardAction() {
        let configuration = SDSelectionActionState.needsSelection.bottomBarConfiguration(
            controller: makeController(metadata: nil)
        )

        #expect(configuration.contextualActions.map(\.titleKey) == [
            "sdSelection.chooseSDCard.button"
        ])
        #expect(configuration.contextualActions.map(\.systemImageName) == [
            "sdcard"
        ])
        #expect(configuration.defaultAction == .contextualAction(index: 0))
    }

    @Test func chooseSDCardActionPresentsVolumeImporter() {
        let controller = makeController(metadata: nil)
        let chooseAction = controller.bottomBarConfiguration.contextualActions.first

        #expect(chooseAction != nil)
        chooseAction?.perform()

        #expect(controller.isVolumeImporterPresented)
    }

    @Test func unsupportedFilesystemSelectionHasUnsupportedFilesystemActionState() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let controller = makeController(metadata: unsupportedFilesystemSecureDigitalMetadata(for: volumeURL))

        controller.handleVolumeSelection(.success([volumeURL]))

        #expect(controller.actionState == .unsupportedFilesystem(hasOpenedDiskUtility: false))
    }

    @Test func unsupportedFilesystemBottomBarOffersDiskUtilityBeforeChooseSDCard() {
        let configuration = SDSelectionActionState.unsupportedFilesystem(
            hasOpenedDiskUtility: false
        ).bottomBarConfiguration(controller: makeController(metadata: nil))

        #expect(configuration.contextualActions.map(\.titleKey) == [
            "sdSelection.openDiskUtility.button",
            "sdSelection.chooseSDCard.button"
        ])
        #expect(configuration.contextualActions.map(\.systemImageName) == [
            "externaldrive.badge.gearshape",
            "sdcard"
        ])
        #expect(configuration.defaultAction == .contextualAction(index: 0))
    }

    @Test func openDiskUtilityTracksLaunchIntentForCurrentSelection() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let diskUtilityOpener = FakeDiskUtilityOpener()
        let controller = makeController(
            metadata: unsupportedFilesystemSecureDigitalMetadata(for: volumeURL),
            diskUtilityOpener: diskUtilityOpener
        )

        controller.handleVolumeSelection(.success([volumeURL]))
        controller.openDiskUtility()

        #expect(diskUtilityOpener.didOpenDiskUtility)
        #expect(controller.actionState == .unsupportedFilesystem(hasOpenedDiskUtility: true))
    }

    @Test func openedDiskUtilityUnsupportedFilesystemDefaultsToChooseSDCard() {
        let configuration = SDSelectionActionState.unsupportedFilesystem(
            hasOpenedDiskUtility: true
        ).bottomBarConfiguration(controller: makeController(metadata: nil))

        #expect(configuration.contextualActions.map(\.titleKey) == [
            "sdSelection.openDiskUtility.button",
            "sdSelection.chooseSDCard.button"
        ])
        #expect(configuration.defaultAction == .contextualAction(index: 1))
    }

    @Test func readySDCardSelectionHasReadyActionState() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let controller = makeController(metadata: readySecureDigitalMetadata(for: volumeURL))

        controller.handleVolumeSelection(.success([volumeURL]))

        #expect(controller.actionState == .ready)
        #expect(controller.readiness?.isReady == true)
    }

    @Test func readyActionStateMakesNextTheDefaultAction() {
        let configuration = SDSelectionActionState.ready.bottomBarConfiguration(
            controller: makeController(metadata: nil)
        )

        #expect(configuration.contextualActions.map(\.titleKey) == [
            "sdSelection.chooseSDCard.button"
        ])
        #expect(configuration.defaultAction == .next)
    }

    @Test func emptyVolumeSelectionShowsNoVolumeSelectedError() {
        let controller = makeController(metadata: nil)

        controller.handleVolumeSelection(.success([]))

        #expect(controller.selectionErrorMessage == String(localized: "sdSelection.error.noVolumeSelected"))
        #expect(controller.selectedDrive == nil)
        #expect(controller.actionState == .needsSelection)
    }

    @Test func failedVolumeSelectionShowsSelectionFailedError() {
        let controller = makeController(metadata: nil)

        controller.handleVolumeSelection(.failure(TestSelectionError.failed))

        #expect(controller.selectionErrorMessage == String(localized: "sdSelection.error.selectionFailed"))
        #expect(controller.selectedDrive == nil)
        #expect(controller.actionState == .needsSelection)
    }

    @Test func revalidateSelectedVolumeUpdatesStaleReadiness() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let metadataProvider = MutableDiskMetadataProvider(
            metadata: readySecureDigitalMetadata(for: volumeURL)
        )
        let controller = makeController(metadataProvider: metadataProvider)

        controller.handleVolumeSelection(.success([volumeURL]))
        #expect(controller.readiness?.isReady == true)

        metadataProvider.metadata = unsupportedFilesystemSecureDigitalMetadata(for: volumeURL)
        controller.revalidateSelectedVolume()

        #expect(controller.readiness == .unavailable(
            reason: .unsupportedFileSystem,
            metadata: unsupportedFilesystemSecureDigitalMetadata(for: volumeURL)
        ))
        #expect(controller.selectedDrive?.volumeURL == volumeURL)
        #expect(controller.actionState == .unsupportedFilesystem(hasOpenedDiskUtility: false))
    }

    @Test func clearSelectionClearsReadinessDriveErrorAndDiskUtilityTracking() {
        let volumeURL = URL(fileURLWithPath: "/Volumes/TestSD")
        let controller = makeController(metadata: unsupportedFilesystemSecureDigitalMetadata(for: volumeURL))

        controller.handleVolumeSelection(.success([volumeURL]))
        controller.clearSelection()

        #expect(controller.readiness == nil)
        #expect(controller.selectedDrive == nil)
        #expect(controller.selectionErrorMessage == nil)
        #expect(!controller.hasOpenedDiskUtilityForCurrentSelection)
        #expect(controller.actionState == .needsSelection)
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
        makeController(
            metadataProvider: MutableDiskMetadataProvider(metadata: metadata),
            diskUtilityOpener: diskUtilityOpener
        )
    }

    private func makeController(
        metadataProvider: MutableDiskMetadataProvider,
        diskUtilityOpener: any DiskUtilityOpening = FakeDiskUtilityOpener()
    ) -> SDSelectionController {
        SDSelectionController(
            scopedAccessManager: ScopedAccessManager(accessSessionFactory: FakeSecurityScopedAccessSessionFactory()),
            sdCardValidationService: SDCardValidationService(
                metadataProvider: metadataProvider
            ),
            diskUtilityOpener: diskUtilityOpener
        )
    }

}

private enum TestSelectionError: Error {
    case failed
}
