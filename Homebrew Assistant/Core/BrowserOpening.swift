//
//  BrowserOpening.swift
//  Homebrew Assistant
//
//  Purpose: Defines the browser launch boundary used by browser-assisted
//  homebrew preparation flows.
//  Owns: Approved URL opening protocol and AppKit-backed production opener.
//  Does not own: Homebrew selection state, URL approval policy, file import,
//  archive validation, staging, SD card writes, or workflow navigation.
//  Used by: Homebrew preparation executors and dashboard tests.
//

import AppKit
import Foundation

protocol BrowserOpening {
    func open(_ url: URL)
}

struct AppKitBrowserOpener: BrowserOpening {
    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
