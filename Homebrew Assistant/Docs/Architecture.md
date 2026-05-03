# Architecture

Homebrew Assistant uses a focused SwiftUI architecture built around clear responsibility boundaries. Views present state and collect user intent. Coordinators, services, models, and utilities own workflow decisions, scoped SD card access, user-selected SD volume validation, signed recipe catalog loading, downloads, staging, archive extraction, writing, verification, diagnostics, sandbox-friendly filesystem access, and trust enforcement.

This document defines file ownership expectations, dependency direction, and responsibility boundaries. Folder and file hierarchy lives in `Structure.md`.

Every production Swift file listed in `Structure.md` should either have its own section here or be covered by a clearly named grouped section. Test files are documented through testing priorities rather than one section per test file.

This document should describe code ownership and dependency boundaries, not user-facing workflow details or recipe trust policy except where needed to explain file responsibilities.

## Core Principles

- Each Swift file should have a narrow, explicit purpose.
- File headers should match the project spec and describe the file’s responsibility.
- Views should not own business logic.
- Lower-level services and models should not depend on SwiftUI views.
- Risky or security-sensitive behavior should live in focused, testable services.
- User selection grants scoped filesystem access; Disk Arbitration validation determines SD card eligibility.
- Filesystem writes should stay inside app-controlled staging directories or the user-approved, validated SD card volume.
- Shared constants, magic strings, schema versions, URL allowlists, repository identifiers, and key metadata should be centralized.
- Ambiguous disk, scoped-access, source, recipe, archive, or verification state should fail safe.

## File Header Format

Where useful, Swift files should use this header structure:

    //  Purpose: ...
    //  Owns: ...
    //  Does not own: ...
    //  Delegates to: ...

Simple files may use a shorter header, but the purpose should still be narrow and explicit.

## Dependency Direction

Preferred dependency flow:

    Views
      ↓
    WorkflowCoordinator / Observable state
      ↓
    Services / Utilities
      ↓
    Models / Native APIs

Rules:

- Views may depend on observable workflow state and coordinators.
- Views should send user intent to coordinators or services.
- Services should expose testable APIs and plain data models.
- Services should not import or depend on SwiftUI views.
- Models should remain UI-independent where practical.
- Utilities should not know about specific views or workflow screens unless explicitly designed for presentation formatting.

## App Layer

### HomebrewAssistantApp.swift

Purpose: Defines the SwiftUI app entry point and creates the main window scene.

Owns:

- App launch declaration
- Main scene creation
- App-level dependency injection through the SwiftUI scene

Does not own:

- Workflow business logic
- Disk operations
- Scoped SD card access
- Downloads
- Staging
- File writes

Delegates to:

- `ContentView`
- App-level dependencies injected through the SwiftUI scene

## Core Layer

### WorkflowCoordinator.swift

Purpose: Coordinates the active workflow session and generated workflow steps.

Owns:

- Current workflow state
- Selected step
- Navigation rules
- Workflow availability decisions
- Unavailable/preparing/prepared/completed/failed status
- Selected internal workflows and public recipes
- Available actions
- High-level workflow transitions
- Cleanup requests when workflows complete, reset, or start over

Does not own:

- Scoped filesystem access implementation
- Disk metadata resolution
- Recipe catalog loading
- Public recipe parsing
- Downloads
- Archive extraction
- Staging file management
- SD card write execution
- Verification execution
- Eject operations
- Cleanup implementation
- Persistent preferences

Delegates to:

- `ScopedAccessManager`
- `DiskManager`
- `RecipeCatalogLoader`
- `InternalWorkflowCatalog`
- `RecipeLoader`
- `ItemPreparationService`
- `DownloadService`
- `StagingManager`
- `SDWriteService`
- `StepStateStore`
- `AppPreferences`

### WorkflowItem.swift

Purpose: Represents an item in the generated workflow sidebar and navigation model.

Owns:

- Stable workflow identifiers
- Ordering metadata
- Step type metadata
- Type discriminator for fixed app step, app-owned internal workflow, or public recipe-driven step
- Localization keys
- Icon references

Does not own:

- Runtime workflow decisions
- Availability and completion state
- Scoped filesystem access
- Disk operations
- Downloads
- Writes
- UI rendering

Delegates to:

- `WorkflowCoordinator` for runtime state and navigation decisions
- `FixedStep`, `InternalWorkflowCatalog`, and `Recipe` for step-specific metadata

### FixedStep.swift

Purpose: Defines fixed app-owned workflow steps that are not recipe or internal workflow preparation items.

Owns:

- Fixed step identities for SD Card Selection, Choose Items, Review Setup, Write and Verify Files, and Success
- Fixed-step ordering
- Basic metadata

Does not own:

- View layout
- Scoped filesystem access
- Download execution
- Disk writes
- Recipe loading
- Internal workflow behavior

Delegates to:

- `WorkflowCoordinator` for runtime transitions
- Step-specific views and services for presentation and work

### InternalWorkflowCatalog.swift

Purpose: Provides app-owned internal workflow item definitions that are selectable alongside public recipes.

Owns:

- Internal workflow kinds
- Internal workflow definition protocol
- Internal workflow list
- Internal workflow ordering metadata
- Internal workflow localization keys and icon references
- Mapping internal workflow identifiers to bundled app-owned behavior

Does not own:

- Public recipe catalog loading
- Public recipe parsing
- Network downloads
- SD card writes
- View rendering

Delegates to:

- `WilbrandWorkflow`
- `HackMiiWorkflow`
- `WorkflowCoordinator`

### WilbrandWorkflow.swift

Purpose: Defines app-owned Wilbrand behavior and trust boundaries.

Owns:

- Approved Wilbrand URL or source pattern
- Browser-to-file-selection flow expectations
- Expected archive shape
- Wilbrand validation requirements
- Staging metadata for Wilbrand output

Does not own:

- Public recipe metadata
- Homebrew Assistant Recipes updates
- Generic archive extraction implementation
- SD card writes
- User-facing copy

Delegates to:

- `ItemPreparationService`
- `DiagnosticsLog`

### HackMiiWorkflow.swift

Purpose: Defines app-owned HackMii bootstrap behavior and trust boundaries.

Owns:

- Approved HackMii source metadata
- Expected files
- Checksum requirements when available
- Staging rules
- Copy intent for the final manifest

Does not own:

- Public recipe metadata
- Homebrew Assistant Recipes updates
- Generic download implementation
- Generic checksum calculation
- SD card writes
- User-facing copy

Delegates to:

- `ItemPreparationService`
- `DiagnosticsLog`

### Recipe.swift

Purpose: Represents declarative public recipe metadata.

Owns:

- Recipe identifiers
- Recipe versions and content versions
- Localization keys
- Approved source metadata
- Expected files
- Checksums
- Allowed roots
- Copy actions
- Overwrite policy
- Post-install instruction keys

Does not own:

- Arbitrary executable behavior
- Shell commands
- Disk formatting or repair
- Workflow navigation
- Download execution
- Archive extraction
- SD card writes

Consumed by:

- `RecipeLoader` for parsing and validation
- `SourcePolicy` for source trust decisions
- `RecipeCatalogLoader` for catalog presentation
- `ItemPreparationService` after validation
- `DownloadService`, `ArchiveExtractor`, `ChecksumVerifier`, and `SDWriteService` indirectly through the preparation and write pipeline

### StepStateStore.swift

Purpose: Stores per-step session state for the active workflow.

Owns:

- Step status such as unavailable, not started, in progress, preparing, prepared, completed, or failed
- Progress values
- Selected options
- Diagnostic messages
- Recoverable error metadata
- Session-only step state

Does not own:

- Workflow navigation rules
- Scoped filesystem access
- Disk operations
- Downloads
- Writes
- Persistent workflow restoration

Delegates to:

- `WorkflowCoordinator` for state transitions
- `DiagnosticsLog` for diagnostic event recording

## Views Layer

### ContentView.swift

Purpose: Hosts the app’s top-level sidebar/detail window layout.

Owns:

- Main window layout composition
- Placement of sidebar, detail, and bottom navigation regions

Does not own:

- Workflow business logic
- Disk operations
- Scoped filesystem access
- Downloads
- Staging
- File writes

Delegates to:

- `WorkflowSidebarView`
- `WorkflowDetailView`
- `BottomNavigationView`
- Shared workflow state

### Components

Component files include:

- `AppStateBadge.swift`
- `PrimaryButton.swift`
- `SecondaryButton.swift`
- `StatusMessageView.swift`

Purpose: Provide reusable presentation building blocks for the app UI.

Own:

- Reusable visual presentation
- Consistent button styling
- Status badge presentation
- Status message layout
- Accessibility labels and traits appropriate to the component

Do not own:

- Workflow decisions
- Step availability
- Business logic
- Service calls
- Disk operations
- Download, staging, write, or verification work

Delegate to:

- Parent views for action handling
- `DesignTokens` and `AppTheme` for styling constants
- Localization resources for user-facing text supplied by parent views

### WorkflowSidebarView.swift

Purpose: Renders the generated workflow sidebar.

Owns:

- Sidebar row presentation
- Step icons and labels
- State indicators
- Selection affordances
- Accessibility labels for meaningful state

Does not own:

- Step ordering decisions
- Workflow availability rules
- Workflow advancement
- Scoped filesystem access
- Disk or recipe operations

Delegates to:

- `WorkflowCoordinator` for selection and reachability decisions
- `WorkflowItem` for step metadata

Unselected optional items are not shown as skipped workflow steps. They simply do not appear in the generated workflow.

### WorkflowDetailView.swift

Purpose: Routes the selected workflow item to the correct detail view.

Owns:

- Detail-view routing
- Fixed step, internal workflow, and public recipe presentation selection

Does not own:

- Workflow decisions
- Service work
- Recipe parsing
- File operations

Delegates to:

- Fixed step views
- Internal workflow views
- `RecipeStepView`
- `WorkflowCoordinator`

### BottomNavigationView.swift

Purpose: Presents shared bottom navigation and step-specific actions.

Owns:

- Lower-left Quit/Back placement
- Lower-right action placement
- Default button presentation rules
- Rule that non-passive or risky actions are never default buttons
- Disabled/enabled button presentation

Does not own:

- Action availability decisions
- Workflow transitions
- Risky operation execution

Delegates to:

- `WorkflowCoordinator` for available actions and user intent handling

### Step Views

Step views include:

- `SDSelectionView.swift`
- `ChooseItemsView.swift`
- `WilbrandView.swift`
- `HackMiiView.swift`
- `ReviewSetupView.swift`
- `WriteFilesView.swift`
- `SuccessView.swift`

Purpose: Present step-specific state and collect user intent.

Own:

- Step layout
- Localized explanatory copy
- Status presentation
- Controls for step-specific user actions
- Accessibility labels

Do not own:

- Workflow availability rules
- Scoped filesystem access implementation
- Disk metadata resolution
- Public recipe catalog loading
- Download execution
- Archive extraction
- Checksum verification
- SD card writes
- Eject implementation
- Cleanup implementation

Delegate to:

- `WorkflowCoordinator`
- Step-specific services
- Shared state models

### SDSelectionView.swift

Purpose: Presents SD card selection and validation state.

Owns:

- Choose SD Card action presentation
- SD card validation result presentation
- Open Disk Utility affordance presentation
- User-facing explanation of scoped SD card access

Does not own:

- Scoped access lifecycle
- Disk Arbitration metadata resolution
- SD card readiness policy
- File writes
- Eject behavior

Delegates to:

- `WorkflowCoordinator`
- `ScopedAccessManager`
- `DiskManager`
- `SDCardReadiness`

### ChooseItemsView.swift

Purpose: Presents selectable internal workflows and public recipes.

Owns:

- Item catalog layout
- Selected/unselected presentation
- Public recipe catalog unavailable/invalid/empty presentation
- Retry affordance presentation
- Trust/source status presentation

Does not own:

- Public recipe catalog loading
- Signed index verification
- Source policy
- Internal workflow behavior
- Recipe preparation

Delegates to:

- `WorkflowCoordinator`
- `RecipeCatalogLoader`
- `InternalWorkflowCatalog`

If the signed public recipe catalog is unavailable, invalid, or empty, internal workflows remain available and the public recipe area shows actionable retry guidance.

### WilbrandView.swift

Purpose: Presents the app-owned Wilbrand preparation step when selected.

Owns:

- Wilbrand instructions presentation
- Open Browser button presentation
- Choose File button presentation
- Wilbrand validation/progress/status presentation

Does not own:

- Approved Wilbrand URL policy
- Archive extraction implementation
- Path safety checks
- Staging implementation
- SD card writes

Delegates to:

- `WorkflowCoordinator`
- `WilbrandWorkflow`
- `ItemPreparationService`

### HackMiiView.swift

Purpose: Presents the app-owned HackMii preparation step when selected.

Owns:

- HackMii instructions presentation
- Download action presentation when applicable
- HackMii preparation/progress/status presentation

Does not own:

- Approved HackMii source policy
- Download or preparation implementation
- Checksum verification
- Staging implementation
- SD card writes

Delegates to:

- `WorkflowCoordinator`
- `HackMiiWorkflow`
- `ItemPreparationService`

### RecipeStepView.swift

Purpose: Presents selected public recipe-driven preparation steps using validated recipe metadata.

Owns:

- Recipe display layout
- Localized recipe title/summary/instruction presentation
- Download and Next control presentation for selected public recipes
- Recipe status presentation

Does not own:

- Recipe catalog loading
- Recipe parsing
- Source trust decisions
- Downloads
- Checksums
- Extraction
- Staging
- SD writes

Delegates to:

- `WorkflowCoordinator`
- `ItemPreparationService`

### ReviewSetupView.swift

Purpose: Presents the final review before writing to the SD card.

Owns:

- Selected item summary presentation
- User-approved, validated SD card summary presentation
- Staged file/write manifest presentation
- Required space and overwrite-warning presentation
- Final write confirmation presentation

Does not own:

- Manifest generation
- SD card validation
- File copying
- Verification
- Source trust decisions

Delegates to:

- `WorkflowCoordinator`
- `StagingManifest`
- `PreparedTool`

### WriteFilesView.swift

Purpose: Presents write and verification progress.

Owns:

- Per-file progress presentation
- Overall progress presentation
- Current operation presentation
- Recoverable/fatal error presentation
- Safe cancellation affordance presentation when available

Does not own:

- File copying
- Verification execution
- Write diagnostics
- SD card validation
- Staging layout creation

Delegates to:

- `WorkflowCoordinator`
- `SDWriteService`
- `DiagnosticsLog`

### SuccessView.swift

Purpose: Presents completion, verification status, next steps, and user-initiated eject.

Owns:

- Success summary presentation
- Prepared item summary presentation
- Verification result presentation
- Next-step instruction presentation
- Eject button presentation
- Start New Workflow presentation

Does not own:

- Eject implementation
- Cleanup implementation
- Verification execution
- Workflow reset implementation

Delegates to:

- `WorkflowCoordinator`
- `DiskManager`
- `DiagnosticsLog`

## Services Layer

### ScopedAccessManager.swift

Purpose: Owns sandbox-friendly scoped filesystem access for the user-selected SD card volume during the active workflow session.

Owns:

- Coordinating the system volume-selection access flow
- Session-only granted volume URL/access state
- Starting and stopping security-scoped access when applicable
- Releasing scoped access on workflow completion, reset, app quit, or start-new-workflow
- Scoped-access diagnostics

Does not own:

- Disk Arbitration validation
- SD card readiness policy
- File copying
- Recipe loading
- Archive extraction
- Workflow navigation
- Persistent bookmarks

Delegates to:

- Native macOS file/folder selection APIs
- Security-scoped resource APIs where applicable
- `WorkflowCoordinator`
- `DiagnosticsLog`

### DiskManager.swift

Purpose: Validates the user-selected mounted volume as a valid Secure Digital card using native macOS Disk Arbitration metadata.

Owns:

- Resolving the user-selected mounted volume to native disk metadata
- Reading disk and volume metadata from macOS
- Validating selected-volume metadata for SD-card eligibility
- Refreshing relevant disk state when hardware or mounted-volume state changes
- User-initiated eject/unmount requests for the approved SD card volume
- SD volume validation diagnostics

Does not own:

- Scoped filesystem access grants or active scoped-access lifecycle
- SD card readiness policy beyond identity/metadata reporting
- Workflow navigation
- File writes
- Formatting
- Erasing
- Repartitioning
- Repairing
- Recipe preparation
- Downloads

Delegates to:

- Disk Arbitration/native macOS APIs
- `SDCard`
- `SDCardReadiness`
- `DiagnosticsLog`

Runtime behavior must accept only the user-selected mounted volume whose Disk Arbitration protocol name is exactly `Secure Digital`. The app must not trust a volume merely because the user selected it; selection grants scoped filesystem access, and Disk Arbitration validation determines eligibility.

### SourcePolicy.swift

Purpose: Centralizes signed catalog, public recipe-source, and payload-source trust decisions.

Owns:

- Homebrew Assistant Recipes repository/source eligibility policy
- Signed index trust policy after `SignedRecipeIndexVerifier` verifies authenticity
- Approved payload source metadata checks
- Official upstream host/repository checks
- Browser-only source handling
- Internal-only capability restrictions
- Wilbrand and HackMii restrictions
- Fail-safe source rejection
- Actionable rejection reasons

Does not own:

- Network downloading
- Recipe parsing
- Checksum calculation
- Archive extraction
- Workflow navigation
- User-facing recipe presentation
- Determining official upstream sources at runtime
- Signing recipe indexes
- Storing private signing keys

Delegates to:

- `AppConstants`
- Trusted recipe/index metadata
- URL parsing
- `ChecksumVerifier`
- `SignedRecipeIndexVerifier`
- `DiagnosticsLog`

### RecipeCatalogLoader.swift

Purpose: Loads the public recipe catalog from the official Homebrew Assistant Recipes repository through the signed Ed25519 recipe index.

Owns:

- Index download/loading
- Calling `SignedRecipeIndexVerifier`
- Recipe checksum verification handoff
- Catalog availability state
- Catalog error mapping
- Unavailable/invalid/empty catalog handling
- Exposing eligible public recipes for `ChooseItemsView`

Does not own:

- Ed25519 signature implementation details
- Internal workflow definitions
- Payload downloads
- Archive extraction
- SD writes
- App-owned Wilbrand/HackMii behavior

Delegates to:

- `SignedRecipeIndexVerifier`
- `SourcePolicy`
- `ChecksumVerifier`
- `RecipeLoader`
- `AppConstants`
- `DiagnosticsLog`

### SignedRecipeIndexVerifier.swift

Purpose: Verifies Homebrew Assistant Recipes signed index authenticity using the compiled-in Ed25519 public verification key and key identifier.

Owns:

- Reading exact index bytes
- Verifying signature metadata such as algorithm and key ID
- Ed25519 signature verification
- Rejection of unsigned or invalid indexes
- Rejection of unknown key identifiers
- Returning verification results without reserializing or pretty-printing JSON

Does not own:

- Network downloading
- Recipe parsing
- Payload source policy
- Checksum verification of individual recipe files
- Private signing keys
- Recipe catalog UI

Delegates to:

- CryptoKit `Curve25519.Signing` verification APIs
- `AppConstants`
- `DiagnosticsLog`

### RecipeLoader.swift

Purpose: Loads and validates public recipe plist content after the signed catalog and recipe checksum have been verified.

Owns:

- Public recipe plist parsing
- Schema validation
- Required-field validation
- Version compatibility checks
- Safe declarative action validation
- Localization and asset reference checks
- Rejection of local/user-selected recipes
- Rejection of loose cached recipes not listed in the verified index
- Rejection of Homebrew Assistant Recipes attempts to modify Wilbrand or HackMii

Does not own:

- Signed index verification
- Network downloads
- Source trust policy
- Checksum calculation
- Archive extraction
- SD card writes
- Workflow navigation

Delegates to:

- `RecipeCatalogLoader`
- `SourcePolicy`
- `ChecksumVerifier`
- `AppConstants`
- `DiagnosticsLog`

### ItemPreparationService.swift

Purpose: Coordinates the preparation pipeline for selected internal workflows and public recipes.

Owns:

- Preparing a selected public recipe item after recipe validation
- Preparing selected app-owned internal workflow items, including Wilbrand and HackMii, when they need shared download/verify/extract/stage behavior
- Sequencing download, checksum verification, extraction, staging, and prepared-item result creation
- Mapping preparation failures to actionable errors
- Reporting preparation diagnostics

Does not own:

- Public recipe catalog loading
- Signed index verification
- Source trust policy
- Disk metadata resolution
- Scoped filesystem access
- Final SD card writes
- Workflow navigation
- User-facing view layout

Delegates to:

- `DownloadService`
- `ChecksumVerifier`
- `ArchiveExtractor`
- `StagingManager`
- `WilbrandWorkflow`
- `HackMiiWorkflow`
- `PreparedTool`
- `DiagnosticsLog`

### DownloadService.swift

Purpose: Downloads approved payload files into the active session staging area.

Owns:

- Network transfer
- Download progress
- Cancellation
- Retry behavior
- Downloaded-file placement
- Download-related errors

Does not own:

- Source trust decisions
- Recipe parsing
- Archive extraction policy
- Checksum/signature verification policy
- Staging session lifecycle
- SD card writes
- Workflow navigation
- User-facing recipe decisions

Delegates to:

- `SourcePolicy`
- `StagingManager`
- `DiagnosticsLog`

### ChecksumVerifier.swift

Purpose: Verifies downloaded or staged files against trusted checksum metadata.

Owns:

- Approved checksum algorithm handling
- Streaming digest calculation
- Expected-versus-actual comparison
- Verification result reporting
- Public recipe file checksum verification against signed index metadata
- Checksum diagnostics

Does not own:

- Network downloads
- Source trust decisions
- Recipe parsing
- Archive extraction
- Staging lifecycle
- Workflow navigation
- SD card writes

Delegates to:

- CryptoKit or approved native hashing APIs
- Recipe checksum metadata
- `DiagnosticsLog`

### ArchiveExtractor.swift

Purpose: Safely extracts approved archives into session staging directories while preventing Zip Slip and related path traversal attacks.

Owns:

- Archive format handling
- Extraction progress
- Zip Slip prevention
- Unsafe path rejection
- Symlink rejection
- Hard-link rejection
- Absolute-path rejection
- Traversal rejection
- Final resolved path containment inside the intended staging directory
- Malformed archive-entry rejection when safety cannot be determined
- Extraction result reporting

Does not own:

- Network downloads
- Source trust decisions
- Recipe parsing
- Staging session lifecycle
- Workflow navigation
- SD card writes
- User-facing recipe decisions

Delegates to:

- `StagingManager` for extraction destinations
- FileManager/native or approved archive APIs
- `DiagnosticsLog`

### SDWriteService.swift

Purpose: Executes the final manifest-based copy to the user-approved, validated SD card volume and verifies copied files.

Owns:

- Safe file-copy execution
- Limiting writes to the approved SD card volume destination
- Overwrite handling after user confirmation
- Per-file and overall progress reporting
- Post-copy verification
- Write-related cancellation where safe
- Write diagnostics

Does not own:

- Workflow navigation
- Recipe preparation
- Downloads
- Archive extraction
- Staging layout creation
- SD card discovery or selected-volume validation
- SD card readiness validation
- Eject operations
- Formatting, erasing, repartitioning, repairing, or other destructive disk operations

Delegates to:

- `StagingManifest`
- `SDCard`
- FileManager/native file APIs
- `DiagnosticsLog`

## Utilities Layer

### StagingManager.swift

Purpose: Owns app-controlled temporary staging for each workflow session.

Owns:

- Unique session staging directories
- Downloads staging
- Extracted archive staging
- Wilbrand import staging
- Prepared layout staging
- Manifest storage within the session directory
- Cleanup boundaries
- Keeping staged writes inside app-controlled session directories

Does not own:

- Network downloads
- Archive extraction policy
- Recipe trust decisions
- Workflow navigation
- SD card writes
- Persistent workflow storage

Delegates to:

- FileManager
- `DiagnosticsLog`

### DiagnosticsLog.swift

Purpose: Collects user-actionable diagnostic events for troubleshooting.

Owns:

- Workflow diagnostic events
- Scoped-access status events
- User-selected SD volume validation events
- Validation failures
- Source-policy rejections
- Download/checksum/extraction/write/verify/eject outcomes

Does not own:

- UI presentation decisions
- Workflow transitions
- Sensitive data collection
- File contents
- Secrets

Diagnostics should avoid unnecessary personal data and full user paths unless required for troubleshooting and clearly appropriate.

### AppConstants.swift

Purpose: Centralizes non-user-facing constants.

Owns:

- Recipe schema versions
- Supported file extensions
- Official Homebrew Assistant Recipes repository identifiers
- Signed recipe index endpoints
- Ed25519 public verification key metadata
- Key identifiers
- URL allowlists
- UserDefaults keys
- Notification names
- Bundle identifiers
- Filesystem path fragments

Does not own:

- User-facing copy
- Private signing keys
- Runtime state
- Workflow decisions

Private signing keys must never live in `AppConstants.swift` or anywhere in the app source tree.

### AppPreferences.swift

Purpose: Owns low-risk persisted preferences and metadata.

Owns:

- Non-sensitive UI preferences
- Optional recipe default selections when safe
- Low-risk app metadata

Does not own or persist:

- Selected SD cards
- Granted mounted paths or active scoped-access state
- Downloads
- Staged files
- Wilbrand imports
- Prepared layouts
- Write manifests
- Workflow execution state

### DesignTokens.swift and AppTheme.swift

Purpose: Provide reusable styling helpers and typed design references.

Own:

- Spacing values
- Corner radii
- Layout measurements
- Animation durations
- Semantic color references
- Approved SF Symbol names
- Reusable view modifiers and styles

Do not own:

- Raw color definitions
- User-facing text
- Workflow decisions

Colors belong in `Assets.xcassets`. User-facing text belongs in localization resources.

## Models Layer

Models should be plain, testable, and UI-independent where practical.

Models must not perform downloads, writes, scoped-access checks, UI navigation, or source-trust decisions.

### SDCard.swift

Purpose: Represents a user-approved mounted volume that has been validated as a Secure Digital card.

Owns:

- Device identifiers
- Volume name
- Granted display path or mount reference
- Capacity and free-space metadata
- Filesystem metadata
- Secure Digital protocol metadata
- Writability/removability traits

Does not own:

- Disk Arbitration queries
- Scoped-access lifecycle
- Readiness policy
- File writes
- UI presentation

Consumed by:

- `DiskManager`
- `SDCardReadiness`
- `WorkflowCoordinator`
- `ReviewSetupView`
- `SuccessView`

### SDCardReadiness.swift

Purpose: Represents readiness validation results for the selected SD card volume.

Owns:

- Readiness status
- Failure reasons
- Warning reasons
- Writable-state result
- Temporary write/read/delete verification result when applicable
- User-actionable readiness messages

Does not own:

- Disk metadata queries
- Scoped-access lifecycle
- File-copy execution
- Formatting or repair
- UI layout

Consumed by:

- `DiskManager`
- `SDSelectionView`
- `WorkflowCoordinator`

### PreparedTool.swift

Purpose: Represents a selected internal workflow or public recipe item after successful preparation.

Owns:

- Prepared item identifier
- Prepared item kind
- Trusted source metadata
- Staged location under the active session directory
- Expected files
- Intended relative destination paths
- Checksums and verification status
- Preparation errors when applicable

Does not own:

- Download execution
- Checksum calculation
- Archive extraction
- Staging directory creation
- SD card writes
- Persistence across launches

Consumed by:

- `ItemPreparationService`
- `WorkflowCoordinator`
- `ReviewSetupView`
- `StagingManifest`

### StagingManifest.swift

Purpose: Represents the current session write plan.

Owns:

- Prepared source paths
- Intended relative destination paths within the approved SD card volume
- File and directory entries to copy
- Overwrite-warning metadata
- Verification expectations
- Source attribution for review and diagnostics

Does not own:

- Staging directory creation
- File copying
- SD card validation
- Source trust decisions
- Workflow navigation

Consumed by:

- `ReviewSetupView`
- `SDWriteService`
- `DiagnosticsLog`

## Testing Architecture

Logic-heavy behavior should be testable without UI automation or physical hardware where practical.

Prioritize tests for:

- User-selected volume validation using injected/fixture disk metadata
- Scoped-access lifecycle behavior
- Workflow availability and navigation
- SourcePolicy trust decisions
- Signed recipe index verification behavior
- RecipeCatalogLoader unavailable, invalid, and empty catalog behavior
- ItemPreparationService preparation sequencing and failure mapping
- RecipeLoader schema and source rejection
- Checksum verification
- Archive extraction safety, including Zip Slip prevention and destination containment
- Staging cleanup boundaries
- SD write planning and verification
- Persistence boundaries
- Localization coverage

## Anti-Patterns

Avoid:

- Views that scan disks, download files, parse recipes, or write to storage.
- Treating user-selected mounted volumes as eligible without Disk Arbitration validation.
- Treating scoped filesystem access as proof that a selected volume is an eligible SD card.
- A `WorkflowCoordinator` that performs service work directly instead of coordinating it.
- A `DownloadService` that owns extraction, source trust, checksum policy, or workflow decisions.
- Views or `WorkflowCoordinator` manually sequencing download, checksum, extraction, and staging instead of delegating preparation to `ItemPreparationService`.
- Internal workflow views bypassing `ItemPreparationService` to call low-level download, checksum, archive extraction, or staging services directly.
- A `SourcePolicy` that guesses official upstream sources at runtime.
- Allowing public recipes to declare internal-only browser, file-selection, exploit, or bootstrap behavior.
- Loose local recipe files treated as trusted.
- Archive extraction that trusts entry paths without containment checks.
- Writes outside app-controlled staging directories or the user-approved, validated SD card volume.
- Any path that allows Homebrew Assistant Recipes to modify Wilbrand or HackMii.
- Hardcoded user-facing strings in production views or services.
- Raw colors outside the asset catalog.
- Private signing keys in the app repo.
