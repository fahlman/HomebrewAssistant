# Architecture

## Document Status

This document describes the current or accepted high-level architecture for Homebrew Assistant.

The code is the truth. File-level ownership is documented in each Swift file header, next to the code it describes. This document should not duplicate every file header or act as a full file-by-file catalog.

Planning, proposals, possible future files, possible renames, and implementation tasks are tracked in GitHub Issues, not in this document.

## Source of Truth

Homebrew Assistant uses this source-of-truth order:

1. Running code
2. File headers that accurately describe that code
3. `Architecture.md` as the high-level architecture guide
4. GitHub Issues as planning memory and implementation tracking

When a file header and this document disagree, update whichever one is stale. For file-specific responsibility, the header should usually win because it is closest to the code.

## Vocabulary

- Workflow session: One user run through the app from setup through SD card write completion, cancellation, reset, or app exit.
- Workflow item: One generated sidebar item in the active workflow session.
- Fixed workflow step: An app-owned workflow step that is always part of the generated workflow, such as SD card selection or the Homebrew dashboard.
- Built-in workflow: App-owned selectable behavior bundled with the app, such as Wilbrand or HackMii, that may require special trusted handling.
- Public recipe: A declarative recipe loaded from the signed Homebrew Assistant Recipes catalog.
- Homebrew option: A selectable dashboard item that may be backed by either a built-in workflow or a public recipe.
- Prepared item: A selected built-in workflow or public recipe item after download, verification, extraction, and staging have succeeded.
- Staging: App-controlled temporary storage used before anything is written to the selected SD card.
- Write manifest: The approved write plan describing staged source files and their intended relative destinations on the validated SD card volume.
- Scoped access: The session-limited filesystem access granted by the user for the selected mounted volume.
- SD card readiness: The validation result that determines whether a selected mounted volume is eligible for Homebrew Assistant writes.

## Core Principles

- Each Swift file should have a narrow, explicit purpose.
- File headers should describe the file’s current local responsibility.
- Views should describe presentation and send user intent to controllers, coordinators, or services.
- Lower-level services and models should not depend on SwiftUI views.
- Risky or security-sensitive behavior should live in focused, testable services.
- User selection grants scoped filesystem access; SD card validation determines SD card eligibility.
- Filesystem writes should stay inside app-controlled staging directories or the user-approved, validated SD card volume.
- Shared constants, magic strings, schema versions, URL allowlists, repository identifiers, and key metadata should be centralized when they exist.
- Ambiguous disk, scoped-access, source, recipe, archive, or verification state should fail safe.

## File Header Format

Where useful, Swift files should use this header structure:

    //  Purpose: ...
    //  Owns: ...
    //  Does not own: ...
    //  Uses: ... / Consumed by: ...

Use `Uses` when a file directly depends on another type or API. Use `Consumed by` when a passive model is read or constructed elsewhere. Avoid `Delegates to` unless the file truly delegates behavior.

Headers should describe what the file does today, not planned or aspirational responsibility. Future work belongs in GitHub Issues.

## Dependency Direction

Preferred dependency flow:

    Views
      ↓
    WorkflowCoordinator / Observable controllers
      ↓
    Services / Utilities
      ↓
    Models / Native APIs

Rules:

- Views may depend on observable workflow state, controllers, and coordinators.
- Views should send user intent to controllers, coordinators, or services.
- Controllers and coordinators should route workflow state and user intent without performing risky service work directly.
- Services should expose testable APIs and plain data models.
- Services should not import or depend on SwiftUI views.
- Models should remain UI-independent where practical.
- Utilities should not know about specific views or workflow screens unless explicitly designed for presentation formatting.

## Architectural Layers

### App

The app layer declares the SwiftUI app entry point, creates the main window scene, and may become the app-level dependency injection entry point when stable shared dependencies exist.

The app layer should not own workflow business logic, disk operations, scoped SD card access, downloads, staging, or file writes.

### Core

The core layer owns workflow session state, generated workflow items, fixed workflow steps, dashboard coordination, internal workflow catalog metadata, step state, and shared workflow actions.

Core types may coordinate user intent and workflow state, but they should not perform risky service work directly. Disk access, validation, preparation, downloads, archive extraction, staging, writing, and ejection should stay behind focused service boundaries when those behaviors exist.

### Models

Models represent app concepts such as workflow items, homebrew options, categories, preparation status, and SD card readiness.

Models should remain plain, UI-independent data where practical. Passive model files should generally say who consumes them rather than claiming to delegate behavior.

### Services

Services own risky behavior, native/API interaction, validation, scoped access, filesystem operations, downloads, verification, extraction, staging, writing, and cleanup when those capabilities exist.

Services should be focused, testable, and safe by default. They should return structured, actionable results where practical and avoid hardcoding user-facing copy.

### Utilities

Utilities provide shared helpers, constants, diagnostics, formatting, or cross-cutting support when those responsibilities have real implementation.

Utilities should not become dumping grounds. If a utility grows unrelated responsibility, split it by domain and track the decision in GitHub Issues.

### Views

Views own presentation, layout, state display, accessibility presentation, and user-intent collection.

Views should not scan disks, validate SD card eligibility, parse recipes, download files, extract archives, stage files, write to the SD card, or perform other risky service work directly.

Placeholder views are acceptable only when they are routed to by real code and keep the app compiling while an accepted feature is not yet implemented. Their headers should clearly say they present placeholder UI.

### Resources

Resources include app-owned assets, localization, and bundled workflow resources when needed.

User-facing strings belong in localization resources. Runtime state, business logic, trust policy, and downloaded payloads do not belong in resources.

### Docs

Documentation files have separate responsibilities:

- `Architecture.md` describes high-level architecture principles, boundaries, vocabulary, and dependency direction.
- `RecipeTrustModel.md` describes recipe trust, signing, source policy, and public recipe safety.
- `Specification.md` describes product behavior, requirements, and expected capabilities.
- `Workflow.md` describes the intended user workflow and high-level app flow.
- GitHub Issues track planning, proposals, possible future files, possible renames, and implementation work.

## SD Card Safety Boundary

SD card workflow safety depends on keeping these concepts separate:

- Scoped access means the user granted session-limited filesystem access to a mounted volume.
- SD card readiness means the selected mounted volume passed eligibility checks for Homebrew Assistant writes.
- A selected volume must not be treated as writable or eligible merely because scoped access exists.
- File writes should target only app-controlled staging locations or the user-approved, validated SD card volume.
- Ambiguous metadata or validation results should fail safe.

## Built-In Workflows and Public Recipes

Built-in workflows are app-owned and may receive special trusted handling. Wilbrand and HackMii are examples of built-in workflows.

Public recipes are declarative and must not be allowed to define built-in-only behavior such as browser-driven exploit setup, bootstrap behavior, or modification of Wilbrand/HackMii handling.

Recipe trust and signing details belong in `RecipeTrustModel.md`. Implementation details belong in the relevant code and file headers once implemented.

## Testing Architecture

Logic-heavy behavior should be testable without UI automation or physical hardware where practical.

Tests should reinforce the project boundaries documented here:

- Views present state and collect user intent.
- Coordinators and controllers own workflow state and user-intent routing.
- Services own risky behavior and native/API interaction.
- Models remain UI-independent where practical.
- Testing backlogs belong in GitHub Issues until the related behavior is implemented or accepted.

## Anti-Patterns

Avoid:

- Views that scan disks, download files, parse recipes, or write to storage.
- Treating user-selected mounted volumes as eligible without SD card readiness validation.
- Treating scoped filesystem access as proof that a selected volume is an eligible SD card.
- A workflow coordinator that performs service work directly instead of coordinating it.
- Views or coordinators manually sequencing preparation work that belongs in accepted preparation services.
- Built-in workflow views bypassing accepted preparation boundaries to call low-level implementation details directly.
- Guessing official upstream sources at runtime.
- Allowing public recipes to declare built-in-only browser, file-selection, exploit, or bootstrap behavior.
- Treating loose local recipe files as trusted.
- Archive extraction that trusts entry paths without containment checks.
- Writes outside app-controlled staging directories or the user-approved, validated SD card volume.
- Any path that allows Homebrew Assistant Recipes to modify Wilbrand or HackMii.
- Hardcoded user-facing strings in production views or services.
- Uncentralized custom/raw colors in production views or services.
- Private signing keys in the app repo.
