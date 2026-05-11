//
//  RecipeStepView.swift
//  Homebrew Assistant
//
//  Purpose: Presents the placeholder UI for public recipe workflow items.
//  Owns: Content-unavailable presentation for recipe steps that are not yet
//  implemented.
//  Does not own: Recipe metadata display, recipe catalog loading, recipe parsing,
//  source trust decisions, downloads, checksums, extraction, staging, SD writes,
//  workflow navigation, or preparation execution.
//  Uses: Localizable strings for placeholder title and description.
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
