//
//  AppStatusStyle.swift
//  Homebrew Assistant
//
//  Purpose: Provides shared semantic foreground colors for app status UI.
//  Owns: Shared success, failure, and neutral foreground colors.
//  Does not own: View layout, status text, workflow state, or domain-specific
//  readiness decisions.
//  Used by: Views and status models that need shared semantic foreground colors.
//

import SwiftUI

enum AppStatusStyle {
    static let successForeground = Color.green
    static let failureForeground = Color.red
    static let neutralForeground = Color.secondary
}
