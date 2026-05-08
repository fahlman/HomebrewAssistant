# Homebrew Assistant Structure

This document lists the planned folder and file hierarchy for the Homebrew Assistant app repository. Detailed file responsibilities live in `Architecture.md`.

```text
Homebrew Assistant/
├── App/
│   └── HomebrewAssistantApp.swift
├── Core/
│   ├── FixedStep.swift
│   ├── HackMiiWorkflow.swift
│   ├── InternalWorkflowCatalog.swift
│   ├── Recipe.swift
│   ├── SDSelectionController.swift
│   ├── StepStateStore.swift
│   ├── WilbrandWorkflow.swift
│   ├── WorkflowCoordinator.swift
│   ├── WorkflowItem.swift
│   └── WorkflowStepAction.swift
├── Docs/
│   ├── Architecture.md
│   ├── Specification.md
│   ├── Structure.md
│   ├── RecipeTrustModel.md
│   └── Workflow.md
├── Models/
│   ├── PreparedTool.swift
│   ├── SDCard.swift
│   ├── SDCardReadiness.swift
│   └── StagingManifest.swift
├── Resources/
│   ├── Assets.xcassets
│   ├── InternalWorkflows/
│   └── Localization/
│       └── Localizable.xcstrings
├── Services/
│   ├── ArchiveExtractor.swift
│   ├── ChecksumVerifier.swift
│   ├── DiskManager.swift
│   ├── DownloadService.swift
│   ├── ItemPreparationService.swift
│   ├── RecipeCatalogLoader.swift
│   ├── RecipeLoader.swift
│   ├── ScopedAccessManager.swift
│   ├── SDWriteService.swift
│   ├── SignedRecipeIndexVerifier.swift
│   └── SourcePolicy.swift
├── Utilities/
│   ├── AppConstants.swift
│   ├── AppPreferences.swift
│   ├── AppTheme.swift
│   ├── DesignTokens.swift
│   ├── DiagnosticsLog.swift
│   └── StagingManager.swift
└── Views/
    ├── Components/
    │   ├── AppStateBadge.swift
    │   ├── AppStatusStyle.swift
    │   ├── PrimaryButton.swift
    │   ├── SecondaryButton.swift
    │   └── StatusMessageView.swift
    ├── ContentView.swift
    ├── Navigation/
    │   ├── BottomNavigationView.swift
    │   ├── WorkflowDetailView.swift
    │   └── WorkflowSidebarView.swift
    ├── Recipe/
    │   └── RecipeStepView.swift
    └── Steps/
        ├── ChooseHomebrewView.swift
        ├── DiskAccessView.swift
        ├── HackMiiView.swift
        ├── ReviewSetupView.swift
        ├── SuccessView.swift
        ├── WilbrandView.swift
        └── WriteFilesView.swift
```


## Tests

```text
Homebrew AssistantTests/
├── AppPreferencesTests.swift
├── ArchiveExtractorTests.swift
├── ChecksumVerifierTests.swift
├── DiskManagerTests.swift
├── DownloadServiceTests.swift
├── HackMiiWorkflowTests.swift
├── ItemPreparationServiceTests.swift
├── LocalizationTests.swift
├── PersistenceTests.swift
├── RecipeCatalogLoaderTests.swift
├── RecipeLoaderTests.swift
├── SDWriteServiceTests.swift
├── ScopedAccessManagerTests.swift
├── SignedRecipeIndexVerifierTests.swift
├── SourcePolicyTests.swift
├── StagingManagerTests.swift
├── StagingManifestTests.swift
├── SuccessViewTests.swift
├── WilbrandWorkflowTests.swift
└── WorkflowCoordinatorTests.swift
```

## Homebrew Assistant Recipes Repository

The separate **Homebrew Assistant Recipes** repository is expected to use this structure:

```text
Homebrew Assistant Recipes/
├── index/
│   ├── recipes.index.json
│   └── recipes.index.signature.json
├── recipes/
│   ├── d2xcios.plist
│   ├── priiloader.plist
│   └── usbloadergx.plist
└── Tools/
    └── RecipeSigner/
        ├── Package.swift
        └── Sources/
            └── RecipeSigner/
                └── main.swift
```
