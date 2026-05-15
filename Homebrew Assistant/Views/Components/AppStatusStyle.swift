//
//  AppStatusStyle.swift
//  Homebrew Assistant
//
//  Purpose: Provides shared semantic foreground colors for app status UI.
//  Owns: Shared success, failure, and neutral foreground colors plus UI-layer
//  status-to-color mapping.
//  Does not own: View layout, status text, workflow state, preparation state,
//  or domain-specific readiness decisions.
//  Used by: Views that need shared semantic foreground colors.
//

internal import SwiftUI

enum AppStatusStyle {
    static let successForeground = Color.green
    static let failureForeground = Color.red
    static let neutralForeground = Color.secondary
}

extension HomebrewPreparationStatus {
    var style: Color {
        switch self {
        case .notSelected, .setupRequired, .readyToDownload, .downloading, .readyToSave, .saving:
            AppStatusStyle.neutralForeground
        case .saved:
            AppStatusStyle.successForeground
        case .failed:
            AppStatusStyle.failureForeground
        }
    }
}
