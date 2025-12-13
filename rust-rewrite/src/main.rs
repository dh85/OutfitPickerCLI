//! Outfit Picker CLI
//!
//! A command-line tool for managing and rotating outfit selections.

use clap::{Parser, Subcommand};
use std::collections::HashSet;
use std::path::PathBuf;

use outfit_picker::domain::error::Result;
use outfit_picker::domain::models::Config;
use outfit_picker::application::picker::OutfitPicker;

#[derive(Parser)]
#[command(name = "outfit-picker")]
#[command(about = "A CLI tool for managing and rotating outfit selections")]
#[command(version)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Initialize the outfit picker with a root directory
    Init {
        /// Path to the root directory containing outfit categories
        #[arg(short, long)]
        root: PathBuf,

        /// Language code for localization (e.g., "en", "es")
        #[arg(short, long, default_value = "en")]
        language: String,
    },

    /// List all categories
    List,

    /// Pick a random outfit
    Pick {
        /// Category to pick from (optional, picks from any if not specified)
        #[arg(short, long)]
        category: Option<String>,
    },

    /// Mark an outfit as worn
    Wear {
        /// Category name
        #[arg(short, long)]
        category: String,

        /// Outfit file name
        #[arg(short, long)]
        outfit: String,
    },

    /// Show rotation status
    Status {
        /// Category to show status for (optional, shows all if not specified)
        #[arg(short, long)]
        category: Option<String>,
    },

    /// Reset rotation progress
    Reset {
        /// Category to reset (optional, resets all if not specified)
        #[arg(short, long)]
        category: Option<String>,

        /// Reset everything (factory reset)
        #[arg(long)]
        factory: bool,
    },

    /// Show worn outfits
    Worn,

    /// Run interactive mode
    Interactive,
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Some(Commands::Init { root, language }) => {
            init_command(root, language).await?;
        }
        Some(Commands::List) => {
            list_command().await?;
        }
        Some(Commands::Pick { category }) => {
            pick_command(category).await?;
        }
        Some(Commands::Wear { category, outfit }) => {
            wear_command(category, outfit).await?;
        }
        Some(Commands::Status { category }) => {
            status_command(category).await?;
        }
        Some(Commands::Reset { category, factory }) => {
            reset_command(category, factory).await?;
        }
        Some(Commands::Worn) => {
            worn_command().await?;
        }
        Some(Commands::Interactive) => {
            interactive_mode().await?;
        }
        None => {
            // Default to interactive mode if no command specified
            interactive_mode().await?;
        }
    }

    Ok(())
}

async fn init_command(root: PathBuf, language: String) -> Result<()> {
    println!("Initializing outfit picker...");

    let config = Config::new(&root, Some(language))?;
    let mut picker = OutfitPicker::new(config.clone())?;

    // Save the configuration
    picker.update_config(config).await?;

    println!("✓ Configuration saved");
    println!("  Root: {}", root.display());

    // Scan categories
    let categories = picker.get_categories().await?;
    println!("  Found {} categories", categories.len());

    for cat in &categories {
        println!(
            "    - {} ({} outfits)",
            cat.category.name, cat.outfit_count
        );
    }

    Ok(())
}

async fn list_command() -> Result<()> {
    let picker = load_picker().await?;
    let categories = picker.get_categories().await?;

    if categories.is_empty() {
        println!("No categories found.");
        return Ok(());
    }

    println!("Categories:");
    for cat in &categories {
        let status = match cat.state {
            outfit_picker::domain::models::CategoryState::HasOutfits => format!("{} outfits", cat.outfit_count),
            outfit_picker::domain::models::CategoryState::Empty => "empty".to_string(),
            outfit_picker::domain::models::CategoryState::NoAvatarFiles => "no avatar files".to_string(),
            outfit_picker::domain::models::CategoryState::UserExcluded => "excluded".to_string(),
        };
        println!("  {} ({})", cat.category.name, status);
    }

    Ok(())
}

async fn pick_command(category: Option<String>) -> Result<()> {
    let picker = load_picker().await?;

    let selection = match category {
        Some(cat) => picker.select_random_outfit(&cat).await?,
        None => picker.select_random_outfit_across_categories().await?,
    };

    match selection {
        Some(sel) => {
            println!("Selected: {}", sel.outfit.file_name);
            println!("Category: {}", sel.outfit.category_name);
            println!("Progress: {:.0}%", sel.rotation_progress * 100.0);
            if sel.rotation_was_reset {
                println!("(Rotation was reset)");
            }
        }
        None => {
            println!("No outfits available.");
        }
    }

    Ok(())
}

async fn wear_command(category: String, outfit: String) -> Result<()> {
    let picker = load_picker().await?;
    picker.wear_outfit(&category, &outfit).await?;
    println!("✓ Marked {} as worn", outfit);
    Ok(())
}

async fn status_command(category: Option<String>) -> Result<()> {
    let picker = load_picker().await?;
    let categories = picker.get_categories().await?;

    for cat in &categories {
        if let Some(ref filter) = category {
            if cat.category.name != *filter {
                continue;
            }
        }

        if cat.state == outfit_picker::domain::models::CategoryState::HasOutfits {
            let outfits = picker.get_outfits(&cat.category.name).await?;
            let mut worn_count = 0;
            for o in &outfits {
                if picker.is_outfit_worn(&cat.category.name, &o.file_name).await? {
                    worn_count += 1;
                }
            }

            let total = outfits.len();
            let progress = if total > 0 {
                (worn_count as f64 / total as f64) * 100.0
            } else {
                100.0
            };

            println!(
                "{}: {}/{} worn ({:.0}%)",
                cat.category.name, worn_count, total, progress
            );
        }
    }

    Ok(())
}

async fn reset_command(category: Option<String>, factory: bool) -> Result<()> {
    let picker = load_picker().await?;

    if factory {
        picker.factory_reset().await?;
        println!("✓ Factory reset complete");
    } else if let Some(cat) = category {
        picker.reset_category(&cat).await?;
        println!("✓ Reset category: {}", cat);
    } else {
        picker.reset_all_categories().await?;
        println!("✓ Reset all categories");
    }

    Ok(())
}

async fn worn_command() -> Result<()> {
    let picker = load_picker().await?;
    let worn = picker.get_all_worn_outfits().await?;

    if worn.is_empty() {
        println!("No outfits have been worn yet.");
        return Ok(());
    }

    println!("Worn outfits:");
    for (category, outfits) in &worn {
        println!("  {}:", category);
        for outfit in outfits {
            println!("    - {}", outfit);
        }
    }

    Ok(())
}

async fn interactive_mode() -> Result<()> {
    let config_service = outfit_picker::infrastructure::config::ConfigService::new()?;
    let is_first_run = !config_service.exists();
    
    let picker = if is_first_run {
        // Create a placeholder picker with a temporary config for first-time setup
        // The TUI will guide the user through setting up the real path
        let temp_config = Config {
            root: std::env::current_dir().unwrap_or_else(|_| PathBuf::from(".")),
            language: Some("en".to_string()),
            excluded_categories: HashSet::new(),
            known_categories: HashSet::new(),
            known_category_files: std::collections::HashMap::new(),
        };
        OutfitPicker::new(temp_config)?
    } else {
        load_picker().await?
    };
    
    outfit_picker::interface::tui::run_interactive_with_setup(picker, is_first_run).await
}

async fn load_picker() -> Result<OutfitPicker> {
    let config_service = outfit_picker::infrastructure::config::ConfigService::new()?;
    let config = config_service.load().await?;
    OutfitPicker::new(config)
}
