//
//  SDCardReadinessTests.swift
//  Homebrew Assistant Tests
//
//  Purpose: Verifies SD card readiness model convenience behavior.
//  Covers: Ready and unavailable readiness classification through `isReady`.
//  Does not cover: Native disk metadata lookup, SD card validation policy,
//  scoped access, UI presentation, file writes, or workflow navigation.
//

import Foundation
import Testing
@testable import Homebrew_Assistant

struct SDCardReadinessTests {
    @Test func readyReadinessIsReady() {
        let readiness = SDCardReadiness.ready(metadata)

        #expect(readiness.isReady)
    }

    @Test func unavailableReadinessIsNotReady() {
        let readiness = SDCardReadiness.unavailable(reason: .unsupportedFileSystem, metadata: metadata)

        #expect(!readiness.isReady)
    }

    private var metadata: DiskVolumeMetadata {
        DiskVolumeMetadata(
            volumeURL: URL(fileURLWithPath: "/Volumes/TestSD"),
            localizedName: "Test SD",
            protocolName: "Secure Digital",
            fileSystemType: "msdos",
            isWritable: true,
            isRemovable: true,
            isEjectable: true,
            isInternal: false
        )
    }
}
