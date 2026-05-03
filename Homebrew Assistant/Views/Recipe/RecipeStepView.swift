//
//  RecipeStepView.swift
//  Homebrew Assistant
//
//  Purpose: Presents selected public recipe-driven preparation steps using validated recipe metadata.
//  Owns: Recipe display layout, localized recipe title/summary/instruction
//  presentation, download and Next control presentation, and recipe status presentation.
//  Does not own: Recipe catalog loading, recipe parsing, source trust decisions,
//  downloads, checksums, extraction, staging, or SD writes.
//  Delegates to: WorkflowCoordinator and ItemPreparationService.
//

import SwiftUI

struct RecipeStepView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "recipeStep.title"),
            systemImage: "shippingbox",
            description: Text(String(localized: "recipeStep.placeholder.description"))
        )
    }
}
