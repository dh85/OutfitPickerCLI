use crate::domain::models::CategoryState;
use super::app::App;
use super::screens::{MainMenuItem, Screen, SettingsMenuItem, SetupStep, WornMenuItem, WornViewMode};

pub async fn handle_enter(app: &mut App) {
    match app.screen {
        Screen::Main => {
            let items = MainMenuItem::all();
            if let Some(i) = app.main_menu_state.selected() {
                match items[i] {
                    MainMenuItem::PickRandom => {
                        match app.picker.select_random_outfit_across_categories().await {
                            Ok(Some(selection)) => {
                                app.message = Some(format!(
                                    "✨ Selected: {} from {}",
                                    selection.outfit.file_name, selection.outfit.category_name
                                ));
                            }
                            Ok(None) => {
                                app.message = Some("No outfits available.".to_string());
                            }
                            Err(e) => {
                                app.message = Some(format!("Error: {}", e));
                            }
                        }
                    }
                    MainMenuItem::BrowseCategories => {
                        app.screen = Screen::CategoryList;
                        // Refresh categories
                        app.categories = app.picker.get_categories().await.unwrap_or_default();
                        if !app.categories.is_empty() {
                            app.category_list_state.select(Some(0));
                        }
                    }
                    MainMenuItem::ViewWorn => {
                        // Navigate to worn outfits menu
                        app.screen = Screen::WornOutfitsMenu;
                        app.worn_menu_state.select(Some(0));
                    }
                    MainMenuItem::ResetProgress => {
                        match app.picker.reset_all_categories().await {
                            Ok(_) => {
                                app.message = Some("✓ All progress reset!".to_string());
                            }
                            Err(e) => {
                                app.message = Some(format!("Error: {}", e));
                            }
                        }
                    }
                    MainMenuItem::Settings => {
                        app.screen = Screen::SettingsMenu;
                        app.settings_menu_state.select(Some(0));
                    }
                    MainMenuItem::Quit => {
                        app.should_quit = true;
                    }
                }
            }
        }
        Screen::CategoryList => {
            if let Some(i) = app.category_list_state.selected() {
                if i < app.categories.len() {
                    let category = &app.categories[i];
                    if category.state == CategoryState::HasOutfits {
                        app.selected_category_index = Some(i);
                        // Load outfits for this category
                        match app.picker.get_outfits(&category.category.name).await {
                            Ok(outfits) => {
                                app.current_category_outfits =
                                    outfits.iter().map(|o| o.file_name.clone()).collect();
                                if !app.current_category_outfits.is_empty() {
                                    app.outfit_list_state.select(Some(0));
                                }
                                app.screen = Screen::CategoryDetail;
                            }
                            Err(e) => {
                                app.message = Some(format!("Error: {}", e));
                            }
                        }
                    } else {
                        app.message = Some(format!(
                            "Category '{}' has no outfits.",
                            category.category.name
                        ));
                    }
                }
            }
        }
        Screen::CategoryDetail => {
            // Select and wear the highlighted outfit
            if let Some(outfit_idx) = app.outfit_list_state.selected() {
                if let Some(cat_idx) = app.selected_category_index {
                    let category_name = app.categories[cat_idx].category.name.clone();
                    let outfit_name = app.current_category_outfits[outfit_idx].clone();

                    match app.picker.wear_outfit(&category_name, &outfit_name).await {
                        Ok(_) => {
                            // Check if rotation is now complete
                            let is_complete = app.picker.is_rotation_complete(&category_name).await.unwrap_or(false);
                            if is_complete {
                                app.message = Some(format!(
                                    "🎉 Rotation complete for '{}'! All outfits worn!",
                                    category_name
                                ));
                            } else {
                                app.message = Some(format!("✓ Marked '{}' as worn!", outfit_name));
                            }
                            // Clear session skips for this category since we wore something
                            app.session.reset_category(&category_name);
                        }
                        Err(e) => {
                            app.message = Some(format!("Error: {}", e));
                        }
                    }
                }
            }
        }
        Screen::WornOutfitsMenu => {
            let items = WornMenuItem::all();
            if let Some(i) = app.worn_menu_state.selected() {
                match items[i] {
                    WornMenuItem::ViewWorn => {
                        app.worn_view_mode = WornViewMode::Worn;
                        load_worn_categories(app, WornViewMode::Worn).await;
                    }
                    WornMenuItem::ViewUnworn => {
                        app.worn_view_mode = WornViewMode::Unworn;
                        load_worn_categories(app, WornViewMode::Unworn).await;
                    }
                    WornMenuItem::Back => {
                        app.screen = Screen::Main;
                    }
                }
            }
        }
        Screen::WornOutfitsList => {
            if app.worn_selected_category.is_none() {
                // Select a category to view its outfits
                if let Some(i) = app.worn_category_state.selected() {
                    if i < app.worn_categories.len() {
                        let category_name = app.worn_categories[i].clone();
                        load_worn_outfits_for_category(app, &category_name).await;
                    }
                }
            }
            // If already viewing outfits, Enter does nothing (or could mark as worn/unworn)
        }
        Screen::SettingsMenu => {
            let items = SettingsMenuItem::all();
            if let Some(i) = app.settings_menu_state.selected() {
                match items[i] {
                    SettingsMenuItem::ChangePath => {
                        app.input_buffer = app.picker.config().root.to_string_lossy().to_string();
                        app.input_cursor = app.input_buffer.len();
                        app.screen = Screen::EditPath;
                    }
                    SettingsMenuItem::ChangeLanguage => {
                        app.input_buffer = app.picker.config().language.clone().unwrap_or_else(|| "en".to_string());
                        app.input_cursor = app.input_buffer.len();
                        app.screen = Screen::EditLanguage;
                    }
                    SettingsMenuItem::ManageExclusions => {
                        let exclusions: Vec<String> = app.picker.config().excluded_categories.iter().cloned().collect();
                        app.input_buffer = exclusions.join(", ");
                        app.input_cursor = app.input_buffer.len();
                        app.screen = Screen::EditExclusions;
                    }
                    SettingsMenuItem::ResetCategory => {
                        // Show category list for reset selection
                        app.categories = app.picker.get_categories().await.unwrap_or_default();
                        if !app.categories.is_empty() {
                            app.reset_category_state.select(Some(0));
                        }
                        app.screen = Screen::Settings;
                    }
                    SettingsMenuItem::ResetAll => {
                        match app.picker.reset_all_categories().await {
                            Ok(_) => {
                                app.message = Some("✓ All categories reset!".to_string());
                            }
                            Err(e) => {
                                app.message = Some(format!("Error: {}", e));
                            }
                        }
                    }
                    SettingsMenuItem::FactoryReset => {
                        match app.picker.factory_reset().await {
                            Ok(_) => {
                                app.message = Some("✓ Factory reset complete. Please restart.".to_string());
                                app.should_quit = true;
                            }
                            Err(e) => {
                                app.message = Some(format!("Error: {}", e));
                            }
                        }
                    }
                    SettingsMenuItem::Back => {
                        app.screen = Screen::Main;
                    }
                }
            }
        }
        Screen::Settings => {
            // Reset selected category
            if let Some(i) = app.reset_category_state.selected() {
                if i < app.categories.len() {
                    let category_name = app.categories[i].category.name.clone();
                    match app.picker.reset_category(&category_name).await {
                        Ok(_) => {
                            app.message = Some(format!("✓ Reset '{}'!", category_name));
                        }
                        Err(e) => {
                            app.message = Some(format!("Error: {}", e));
                        }
                    }
                }
            }
        }
        _ => {}
    }
}

/// Handle input submission for text editing screens
pub async fn handle_input_submit(app: &mut App) {
    match app.screen {
        Screen::EditPath => {
            let new_path = app.input_buffer.trim().to_string();
            if new_path.is_empty() {
                app.message = Some("Path cannot be empty.".to_string());
                return;
            }
            
            let path = std::path::PathBuf::from(&new_path);
            if !path.exists() {
                app.message = Some("Path does not exist.".to_string());
                return;
            }
            
            // Create new config with new path
            match crate::domain::models::Config::new(&path, app.picker.config().language.clone()) {
                Ok(mut new_config) => {
                    new_config.excluded_categories = app.picker.config().excluded_categories.clone();
                    match app.picker.update_config(new_config).await {
                        Ok(_) => {
                            app.message = Some("✓ Path updated!".to_string());
                            app.screen = Screen::SettingsMenu;
                            app.input_buffer.clear();
                            app.input_cursor = 0;
                            // Refresh categories
                            app.categories = app.picker.get_categories().await.unwrap_or_default();
                        }
                        Err(e) => {
                            app.message = Some(format!("Error: {}", e));
                        }
                    }
                }
                Err(e) => {
                    app.message = Some(format!("Invalid path: {}", e));
                }
            }
        }
        Screen::EditLanguage => {
            let new_lang = app.input_buffer.trim().to_string();
            let lang_option = if new_lang.is_empty() { None } else { Some(new_lang.clone()) };
            
            if let Some(ref lang) = lang_option {
                if !crate::domain::models::Config::is_supported_language(lang) {
                    app.message = Some(format!("Unsupported language: {}. Use a 2-letter ISO code.", lang));
                    return;
                }
            }
            
            // Create new config with new language
            match crate::domain::models::Config::new(&app.picker.config().root, lang_option) {
                Ok(mut new_config) => {
                    new_config.excluded_categories = app.picker.config().excluded_categories.clone();
                    match app.picker.update_config(new_config).await {
                        Ok(_) => {
                            app.message = Some("✓ Language updated!".to_string());
                            app.screen = Screen::SettingsMenu;
                            app.input_buffer.clear();
                            app.input_cursor = 0;
                        }
                        Err(e) => {
                            app.message = Some(format!("Error: {}", e));
                        }
                    }
                }
                Err(e) => {
                    app.message = Some(format!("Error: {}", e));
                }
            }
        }
        Screen::EditExclusions => {
            let input = app.input_buffer.trim();
            let exclusions: std::collections::HashSet<String> = if input.is_empty() {
                std::collections::HashSet::new()
            } else {
                input.split(',')
                    .map(|s| s.trim().to_string())
                    .filter(|s| !s.is_empty())
                    .collect()
            };
            
            // Create new config with new exclusions
            match crate::domain::models::Config::new(&app.picker.config().root, app.picker.config().language.clone()) {
                Ok(mut new_config) => {
                    new_config.excluded_categories = exclusions;
                    match app.picker.update_config(new_config).await {
                        Ok(_) => {
                            app.message = Some("✓ Exclusions updated!".to_string());
                            app.screen = Screen::SettingsMenu;
                            app.input_buffer.clear();
                            app.input_cursor = 0;
                            // Refresh categories
                            app.categories = app.picker.get_categories().await.unwrap_or_default();
                        }
                        Err(e) => {
                            app.message = Some(format!("Error: {}", e));
                        }
                    }
                }
                Err(e) => {
                    app.message = Some(format!("Error: {}", e));
                }
            }
        }
        Screen::FirstTimeSetup => {
            match app.setup_step {
                SetupStep::Path => {
                    let path = app.input_buffer.trim().to_string();
                    if path.is_empty() {
                        app.message = Some("Path cannot be empty.".to_string());
                        return;
                    }
                    
                    let path_buf = std::path::PathBuf::from(&path);
                    if !path_buf.exists() {
                        app.message = Some("Path does not exist. Please enter a valid directory.".to_string());
                        return;
                    }
                    
                    // Create initial config
                    match crate::domain::models::Config::new(&path_buf, Some("en".to_string())) {
                        Ok(new_config) => {
                            match app.picker.update_config(new_config).await {
                                Ok(_) => {
                                    app.message = Some("✓ Path saved!".to_string());
                                    app.input_buffer = "en".to_string();
                                    app.input_cursor = app.input_buffer.len();
                                    app.setup_step = SetupStep::Language;
                                }
                                Err(e) => {
                                    app.message = Some(format!("Error: {}", e));
                                }
                            }
                        }
                        Err(e) => {
                            app.message = Some(format!("Invalid path: {}", e));
                        }
                    }
                }
                SetupStep::Language => {
                    let lang = app.input_buffer.trim().to_string();
                    let lang_option = if lang.is_empty() { None } else { Some(lang.clone()) };
                    
                    if let Some(ref l) = lang_option {
                        if !crate::domain::models::Config::is_supported_language(l) {
                            app.message = Some(format!("Unsupported language: {}. Use a 2-letter ISO code (e.g., en, es, fr).", l));
                            return;
                        }
                    }
                    
                    match crate::domain::models::Config::new(&app.picker.config().root, lang_option) {
                        Ok(new_config) => {
                            match app.picker.update_config(new_config).await {
                                Ok(_) => {
                                    app.message = Some("✓ Language saved!".to_string());
                                    app.input_buffer.clear();
                                    app.input_cursor = 0;
                                    app.setup_step = SetupStep::Exclusions;
                                }
                                Err(e) => {
                                    app.message = Some(format!("Error: {}", e));
                                }
                            }
                        }
                        Err(e) => {
                            app.message = Some(format!("Error: {}", e));
                        }
                    }
                }
                SetupStep::Exclusions => {
                    let input = app.input_buffer.trim();
                    let exclusions: std::collections::HashSet<String> = if input.is_empty() {
                        std::collections::HashSet::new()
                    } else {
                        input.split(',')
                            .map(|s| s.trim().to_string())
                            .filter(|s| !s.is_empty())
                            .collect()
                    };
                    
                    match crate::domain::models::Config::new(&app.picker.config().root, app.picker.config().language.clone()) {
                        Ok(mut new_config) => {
                            new_config.excluded_categories = exclusions;
                            match app.picker.update_config(new_config).await {
                                Ok(_) => {
                                    app.message = Some("✓ Setup complete! Welcome to Outfit Picker!".to_string());
                                    app.setup_step = SetupStep::Complete;
                                    app.input_buffer.clear();
                                    app.input_cursor = 0;
                                    // Load categories and go to main menu
                                    app.categories = app.picker.get_categories().await.unwrap_or_default();
                                    if !app.categories.is_empty() {
                                        app.category_list_state.select(Some(0));
                                    }
                                    app.screen = Screen::Main;
                                    app.is_first_run = false;
                                }
                                Err(e) => {
                                    app.message = Some(format!("Error: {}", e));
                                }
                            }
                        }
                        Err(e) => {
                            app.message = Some(format!("Error: {}", e));
                        }
                    }
                }
                SetupStep::Complete => {
                    app.screen = Screen::Main;
                }
            }
        }
        _ => {}
    }
}

/// Load categories that have worn/unworn outfits
async fn load_worn_categories(app: &mut App, mode: WornViewMode) {
    let categories = app.picker.get_categories().await.unwrap_or_default();
    let mut result_categories = Vec::new();

    for cat in &categories {
        if cat.state != CategoryState::HasOutfits {
            continue;
        }
        
        match mode {
            WornViewMode::Worn => {
                if let Ok(worn) = app.picker.get_worn_outfits(&cat.category.name).await {
                    if !worn.is_empty() {
                        result_categories.push(cat.category.name.clone());
                    }
                }
            }
            WornViewMode::Unworn => {
                if let Ok(unworn) = app.picker.get_unworn_outfits(&cat.category.name).await {
                    if !unworn.is_empty() {
                        result_categories.push(cat.category.name.clone());
                    }
                }
            }
        }
    }

    if result_categories.is_empty() {
        let mode_str = match mode {
            WornViewMode::Worn => "worn",
            WornViewMode::Unworn => "unworn",
        };
        app.message = Some(format!("No {} outfits found.", mode_str));
    } else {
        app.worn_categories = result_categories;
        app.worn_selected_category = None;
        app.worn_category_state.select(Some(0));
        app.screen = Screen::WornOutfitsList;
    }
}

/// Load outfits for a specific category
async fn load_worn_outfits_for_category(app: &mut App, category_name: &str) {
    let outfits = match app.worn_view_mode {
        WornViewMode::Worn => app.picker.get_worn_outfits(category_name).await,
        WornViewMode::Unworn => app.picker.get_unworn_outfits(category_name).await,
    };

    match outfits {
        Ok(list) => {
            app.worn_outfits_display = list.iter().map(|o| o.file_name.clone()).collect();
            app.worn_selected_category = Some(category_name.to_string());
            if !app.worn_outfits_display.is_empty() {
                app.worn_outfit_state.select(Some(0));
            }
        }
        Err(e) => {
            app.message = Some(format!("Error loading outfits: {}", e));
        }
    }
}

/// Handle skip action - skip the currently selected outfit
pub async fn handle_skip(app: &mut App) {
    match app.screen {
        Screen::CategoryDetail => {
            if let Some(outfit_idx) = app.outfit_list_state.selected() {
                if outfit_idx < app.current_category_outfits.len() {
                    if let Some(cat_idx) = app.selected_category_index {
                        let category_name = app.categories[cat_idx].category.name.clone();
                        let outfit_name = app.current_category_outfits[outfit_idx].clone();
                        
                        app.session.skip_in_category(&category_name, &outfit_name);
                        app.message = Some(format!("⏭ Skipped '{}' for this session", outfit_name));
                        
                        // Move to next outfit if available
                        if outfit_idx + 1 < app.current_category_outfits.len() {
                            app.outfit_list_state.select(Some(outfit_idx + 1));
                        } else if outfit_idx > 0 {
                            app.outfit_list_state.select(Some(outfit_idx - 1));
                        }
                    }
                }
            }
        }
        Screen::Main => {
            // On main menu, 's' could skip the last suggested outfit globally
            app.message = Some("💡 Use 's' in category detail to skip outfits".to_string());
        }
        _ => {}
    }
}

/// Reset session skips or category rotation
pub async fn handle_reset(app: &mut App) {
    match app.screen {
        Screen::CategoryDetail => {
            // Reset skips for current category only
            if let Some(cat_idx) = app.selected_category_index {
                let category_name = &app.categories[cat_idx].category.name;
                app.session.reset_category(category_name);
                app.message = Some(format!("🔄 Reset skipped outfits for '{}'", category_name));
            }
        }
        Screen::CategoryList => {
            // Reset rotation for the highlighted category
            if let Some(i) = app.category_list_state.selected() {
                if i < app.categories.len() {
                    let category_name = app.categories[i].category.name.clone();
                    match app.picker.reset_category(&category_name).await {
                        Ok(_) => {
                            app.message = Some(format!("🔄 Reset rotation for '{}'", category_name));
                        }
                        Err(e) => {
                            app.message = Some(format!("Error: {}", e));
                        }
                    }
                }
            }
        }
        Screen::Main => {
            // Reset all session skips
            app.session.reset_all();
            app.message = Some("🔄 Reset all skipped outfits for this session".to_string());
        }
        _ => {}
    }
}

/// Pick a random outfit from the selected category
pub async fn handle_pick_random(app: &mut App) {
    match app.screen {
        Screen::CategoryList => {
            // Pick random from the highlighted category
            if let Some(i) = app.category_list_state.selected() {
                if i < app.categories.len() {
                    let category = &app.categories[i];
                    if category.state == CategoryState::HasOutfits {
                        let category_name = category.category.name.clone();
                        match app.picker.select_random_outfit(&category_name).await {
                            Ok(Some(selection)) => {
                                if selection.rotation_was_reset {
                                    app.message = Some(format!(
                                        "🎉 Rotation complete for '{}'! Picked: {} (starting new rotation)",
                                        category_name, selection.outfit.file_name
                                    ));
                                } else {
                                    let progress_pct = (selection.rotation_progress * 100.0) as u8;
                                    app.message = Some(format!(
                                        "🎲 Picked: {} [{}% worn]",
                                        selection.outfit.file_name, progress_pct
                                    ));
                                }
                            }
                            Ok(None) => {
                                app.message = Some(format!(
                                    "No unworn outfits in '{}'.",
                                    category_name
                                ));
                            }
                            Err(e) => {
                                app.message = Some(format!("Error: {}", e));
                            }
                        }
                    } else {
                        app.message = Some(format!(
                            "Category '{}' has no outfits.",
                            category.category.name
                        ));
                    }
                }
            }
        }
        Screen::CategoryDetail => {
            // Pick random from the current category
            if let Some(cat_idx) = app.selected_category_index {
                let category_name = app.categories[cat_idx].category.name.clone();
                match app.picker.select_random_outfit(&category_name).await {
                    Ok(Some(selection)) => {
                        if selection.rotation_was_reset {
                            app.message = Some(format!(
                                "🎉 Rotation complete! Picked: {} (starting new rotation)",
                                selection.outfit.file_name
                            ));
                        } else {
                            let progress_pct = (selection.rotation_progress * 100.0) as u8;
                            app.message = Some(format!(
                                "🎲 Picked: {} [{}% worn]",
                                selection.outfit.file_name, progress_pct
                            ));
                        }
                    }
                    Ok(None) => {
                        app.message = Some(format!(
                            "No unworn outfits in '{}'.",
                            category_name
                        ));
                    }
                    Err(e) => {
                        app.message = Some(format!("Error: {}", e));
                    }
                }
            }
        }
        _ => {}
    }
}
