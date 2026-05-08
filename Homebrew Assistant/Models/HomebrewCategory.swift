//
//  HomebrewCategory.swift
//  Homebrew Assistant
//
//  Created by Ryan Fahlsing on 5/7/26.
//


//
//  HomebrewCategory.swift
//  Homebrew Assistant
//
//  Purpose: Defines shared homebrew category values used by internal workflows
//  and public recipes.
//  Owns: Category identifiers, localized category title keys, category display
//  titles, and category sort order.
//  Does not own: Homebrew option selection, recipe loading, internal workflow
//  behavior, filtering UI, sorting UI, or workflow navigation.
//  Delegates to: Localizable strings for user-facing category titles.
//

import Foundation

enum HomebrewCategory: Int, CaseIterable, Comparable, Identifiable {
    case apps
    case exploits
    case installers
    case utilities
    case wads

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .apps:
            "chooseHomebrew.category.apps"
        case .exploits:
            "chooseHomebrew.category.exploits"
        case .installers:
            "chooseHomebrew.category.installers"
        case .utilities:
            "chooseHomebrew.category.utilities"
        case .wads:
            "chooseHomebrew.category.wads"
        }
    }

    var title: String {
        String(localized: String.LocalizationValue(titleKey))
    }

    static func < (lhs: HomebrewCategory, rhs: HomebrewCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
