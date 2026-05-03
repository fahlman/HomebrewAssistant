//
//  AppStatusStyle.swift
//  Homebrew Assistant
//
//  Purpose: Provides shared semantic status styling for app UI components.
//  Owns: Shared success, failure, and neutral foreground styles for status UI.
//  Does not own: View layout, status text, workflow state, or domain-specific
//  readiness decisions.
//  Delegates to: Individual views for applying these styles in context.
//

import SwiftUI

enum AppStatusStyle {
    static let success = Color.green
    static let failure = Color.red
    static let neutral = Color.secondary
}
