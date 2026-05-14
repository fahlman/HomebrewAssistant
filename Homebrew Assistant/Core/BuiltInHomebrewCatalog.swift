//
//  BuiltInHomebrewCatalog.swift
//  Homebrew Assistant
//
//  Purpose: Provides built-in homebrew metadata that is selectable through the
//  Choose Homebrew dashboard.
//  Owns: Ordered built-in homebrew metadata and mapping built-in homebrew kinds
//  to dashboard option metadata.
//  Does not own: Built-in homebrew identity, public recipe catalog loading,
//  public recipe parsing, network downloads, SD card writes, preparation
//  execution, workflow navigation, or view rendering.
//  Used by: HomebrewDashboardController and catalog tests.
//

import Foundation

struct BuiltInHomebrewCatalog {
    let homebrewKinds: [BuiltInHomebrewKind]

    init(homebrewKinds: [BuiltInHomebrewKind] = BuiltInHomebrewKind.allCases) {
        self.homebrewKinds = homebrewKinds.sorted { first, second in
            first.sortOrder < second.sortOrder
        }
    }

    var homebrewOptions: [HomebrewOption] {
        homebrewKinds.map { kind in
            HomebrewOption(kind: kind)
        }
    }
}
