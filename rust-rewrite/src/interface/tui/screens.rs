/// The different screens/views in the TUI.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Screen {
    Main,
    CategoryList,
    CategoryDetail,
    WornOutfitsMenu,
    WornOutfitsList,
    Settings,
    SettingsMenu,
    EditPath,
    EditLanguage,
    EditExclusions,
    FirstTimeSetup,
    Help,
}

/// The main menu options.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MainMenuItem {
    PickRandom,
    BrowseCategories,
    ViewWorn,
    ResetProgress,
    Settings,
    Quit,
}

impl MainMenuItem {
    pub fn all() -> Vec<Self> {
        vec![
            Self::PickRandom,
            Self::BrowseCategories,
            Self::ViewWorn,
            Self::ResetProgress,
            Self::Settings,
            Self::Quit,
        ]
    }

    pub fn label(&self) -> &'static str {
        match self {
            Self::PickRandom => "🎲 Pick Random Outfit",
            Self::BrowseCategories => "📁 Browse Categories",
            Self::ViewWorn => "👔 View Worn Outfits",
            Self::ResetProgress => "🔄 Reset Progress",
            Self::Settings => "⚙️  Settings",
            Self::Quit => "🚪 Quit",
        }
    }
}

/// Worn outfits menu options.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WornMenuItem {
    ViewWorn,
    ViewUnworn,
    Back,
}

impl WornMenuItem {
    pub fn all() -> Vec<Self> {
        vec![Self::ViewWorn, Self::ViewUnworn, Self::Back]
    }

    pub fn label(&self) -> &'static str {
        match self {
            Self::ViewWorn => "👔 View Worn Outfits",
            Self::ViewUnworn => "✨ View Unworn Outfits",
            Self::Back => "← Back to Main Menu",
        }
    }
}

/// What type of outfits we're viewing (worn or unworn).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WornViewMode {
    Worn,
    Unworn,
}

/// Settings menu options.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SettingsMenuItem {
    ChangePath,
    ChangeLanguage,
    ManageExclusions,
    ResetCategory,
    ResetAll,
    FactoryReset,
    Back,
}

impl SettingsMenuItem {
    pub fn all() -> Vec<Self> {
        vec![
            Self::ChangePath,
            Self::ChangeLanguage,
            Self::ManageExclusions,
            Self::ResetCategory,
            Self::ResetAll,
            Self::FactoryReset,
            Self::Back,
        ]
    }

    pub fn label(&self) -> &'static str {
        match self {
            Self::ChangePath => "Change Outfit Path",
            Self::ChangeLanguage => "Change Language",
            Self::ManageExclusions => "Manage Excluded Categories",
            Self::ResetCategory => "Reset Category Progress",
            Self::ResetAll => "Reset All Progress",
            Self::FactoryReset => "Factory Reset",
            Self::Back => "Back",
        }
    }
}

/// Steps in the first-time setup wizard.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SetupStep {
    Path,
    Language,
    Exclusions,
    Complete,
}
