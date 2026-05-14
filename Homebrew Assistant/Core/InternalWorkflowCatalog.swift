//
//  InternalWorkflowCatalog.swift
//  Homebrew Assistant
//
//  Purpose: Provides built-in homebrew metadata that is selectable through the
//  Choose Homebrew dashboard.
//  Owns: Built-in homebrew identity, ordered built-in homebrew metadata, and
//  mapping built-in homebrew kinds to dashboard option metadata.
//  Does not own: Public recipe catalog loading, public recipe parsing, network
//  downloads, SD card writes, preparation execution, workflow navigation, or
//  view rendering.
//

import Foundation

struct InternalWorkflowCatalog {
    let workflows: [BuiltInHomebrewKind]

    init(workflows: [BuiltInHomebrewKind] = BuiltInHomebrewKind.allCases) {
        self.workflows = workflows.sorted { first, second in
            first.sortOrder < second.sortOrder
        }
    }

    var homebrewOptions: [HomebrewOption] {
        workflows.map { kind in
            HomebrewOption(kind: kind)
        }
    }
}
