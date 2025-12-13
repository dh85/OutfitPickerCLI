use ratatui::{
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, Paragraph},
    Frame,
};

use crate::domain::models::CategoryState;
use super::app::App;
use super::screens::{MainMenuItem, Screen, SettingsMenuItem, SetupStep, WornMenuItem, WornViewMode};

pub fn ui(f: &mut Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3), // Header
            Constraint::Min(10),   // Main content
            Constraint::Length(3), // Footer/message
        ])
        .split(f.size());

    // Header
    let header = Paragraph::new("🎽 Outfit Picker")
        .style(Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD))
        .block(Block::default().borders(Borders::ALL));
    f.render_widget(header, chunks[0]);

    // Main content based on screen
    match app.screen {
        Screen::Main => render_main_menu(f, app, chunks[1]),
        Screen::CategoryList => render_category_list(f, app, chunks[1]),
        Screen::CategoryDetail => render_category_detail(f, app, chunks[1]),
        Screen::WornOutfitsMenu => render_worn_menu(f, app, chunks[1]),
        Screen::WornOutfitsList => render_worn_outfits_list(f, app, chunks[1]),
        Screen::Settings => render_settings(f, app, chunks[1]),
        Screen::SettingsMenu => render_settings_menu(f, app, chunks[1]),
        Screen::EditPath => render_edit_path(f, app, chunks[1]),
        Screen::EditLanguage => render_edit_language(f, app, chunks[1]),
        Screen::EditExclusions => render_edit_exclusions(f, app, chunks[1]),
        Screen::FirstTimeSetup => render_first_time_setup(f, app, chunks[1]),
        Screen::Help => render_help(f, chunks[1]),
    }

    // Footer/message
    let (footer_text, footer_style) = if let Some(ref msg) = app.message {
        let style = if msg.contains("Error") || msg.contains("error") {
            Style::default().fg(Color::Red).add_modifier(Modifier::BOLD)
        } else if msg.contains("🎉") || msg.contains("✓") {
            Style::default().fg(Color::Green).add_modifier(Modifier::BOLD)
        } else if msg.contains("🎲") {
            Style::default().fg(Color::Yellow)
        } else if msg.contains("🔄") || msg.contains("⏭") {
            Style::default().fg(Color::Cyan)
        } else if msg.contains("💡") {
            Style::default().fg(Color::Blue)
        } else {
            Style::default().fg(Color::White)
        };
        (msg.clone(), style)
    } else {
        let text = match app.screen {
            Screen::CategoryList => {
                "↑↓ Navigate | Enter Browse | p Pick Random | r Reset Rotation | Esc Back".to_string()
            }
            Screen::CategoryDetail => {
                let skip_count = if let Some(cat_idx) = app.selected_category_index {
                    let cat_name = &app.categories[cat_idx].category.name;
                    app.session.skipped_count_in_category(cat_name)
                } else {
                    0
                };
                if skip_count > 0 {
                    format!("↑↓ Navigate | Enter Wear | p Pick Random | s Skip ({} skipped) | r Reset | Esc", skip_count)
                } else {
                    "↑↓ Navigate | Enter Wear | p Pick Random | s Skip | r Reset | Esc Back".to_string()
                }
            }
            Screen::Main => {
                "↑↓ Navigate | Enter Select | p Pick Random | q Quit | ? Help".to_string()
            }
            Screen::SettingsMenu => {
                "↑↓ Navigate | Enter Select | Esc Back".to_string()
            }
            Screen::EditPath | Screen::EditLanguage | Screen::EditExclusions => {
                "Type to edit | Enter Submit | Esc Cancel".to_string()
            }
            Screen::FirstTimeSetup => {
                "Type to edit | Enter Continue | Tab Skip".to_string()
            }
            _ => "↑↓ Navigate | Enter Select | Esc Back | q Quit | ? Help".to_string(),
        };
        (text, Style::default().fg(Color::Gray))
    };
    let footer = Paragraph::new(footer_text)
        .style(footer_style)
        .block(Block::default().borders(Borders::ALL));
    f.render_widget(footer, chunks[2]);
}

fn render_main_menu(f: &mut Frame, app: &App, area: Rect) {
    let items: Vec<ListItem> = MainMenuItem::all()
        .iter()
        .map(|item| {
            let (icon, color) = match item {
                MainMenuItem::PickRandom => ("🎲", Color::Green),
                MainMenuItem::BrowseCategories => ("📂", Color::Blue),
                MainMenuItem::ViewWorn => ("👁️", Color::Yellow),
                MainMenuItem::ResetProgress => ("🔄", Color::Cyan),
                MainMenuItem::Settings => ("⚙️", Color::Gray),
                MainMenuItem::Quit => ("🚪", Color::Red),
            };
            ListItem::new(format!("{} {}", icon, item.label()))
                .style(Style::default().fg(color))
        })
        .collect();

    let list = List::new(items)
        .block(Block::default().title("Main Menu").borders(Borders::ALL))
        .highlight_style(
            Style::default()
                .fg(Color::Yellow)
                .add_modifier(Modifier::BOLD)
                .add_modifier(Modifier::REVERSED),
        )
        .highlight_symbol("▶ ");

    f.render_stateful_widget(list, area, &mut app.main_menu_state.clone());
}

fn render_category_list(f: &mut Frame, app: &App, area: Rect) {
    let items: Vec<ListItem> = app
        .categories
        .iter()
        .map(|cat| {
            let (status, style) = match cat.state {
                CategoryState::HasOutfits => {
                    let worn = cat.worn_count;
                    let total = cat.outfit_count;
                    let (color, indicator) = if worn >= total && total > 0 {
                        (Color::Magenta, " ✓") // All worn - rotation complete
                    } else if worn > 0 {
                        (Color::Green, "") // Partially worn
                    } else {
                        (Color::Cyan, "") // Fresh/unworn
                    };
                    (format!("({}/{} worn{})", worn, total, indicator), Style::default().fg(color))
                }
                CategoryState::Empty => ("(empty)".to_string(), Style::default().fg(Color::DarkGray)),
                CategoryState::NoAvatarFiles => ("(no avatars)".to_string(), Style::default().fg(Color::DarkGray)),
                CategoryState::UserExcluded => ("(excluded)".to_string(), Style::default().fg(Color::Red)),
            };
            ListItem::new(format!("{} {}", cat.category.name, status)).style(style)
        })
        .collect();

    let list = List::new(items)
        .block(
            Block::default()
                .title("Categories")
                .borders(Borders::ALL),
        )
        .highlight_style(
            Style::default()
                .fg(Color::Yellow)
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol("▶ ");

    f.render_stateful_widget(list, area, &mut app.category_list_state.clone());
}

fn render_category_detail(f: &mut Frame, app: &App, area: Rect) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(3), Constraint::Min(5)])
        .split(area);

    // Category header with progress
    let category_name = app
        .selected_category_index
        .and_then(|i| app.categories.get(i))
        .map(|c| c.category.name.clone())
        .unwrap_or_default();

    let header = Paragraph::new(format!("📁 {}", category_name))
        .style(Style::default().fg(Color::Cyan))
        .block(Block::default().borders(Borders::ALL));
    f.render_widget(header, chunks[0]);

    // Outfit list
    let items: Vec<ListItem> = app
        .current_category_outfits
        .iter()
        .map(|outfit| ListItem::new(format!("  {}", outfit)))
        .collect();

    let list = List::new(items)
        .block(
            Block::default()
                .title("Outfits (Enter to mark as worn)")
                .borders(Borders::ALL),
        )
        .highlight_style(
            Style::default()
                .fg(Color::Yellow)
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol("▶ ");

    f.render_stateful_widget(list, chunks[1], &mut app.outfit_list_state.clone());
}

fn render_worn_menu(f: &mut Frame, app: &App, area: Rect) {
    let items: Vec<ListItem> = WornMenuItem::all()
        .iter()
        .map(|item| ListItem::new(item.label()))
        .collect();

    let list = List::new(items)
        .block(Block::default().title("View Worn/Unworn").borders(Borders::ALL))
        .highlight_style(
            Style::default()
                .fg(Color::Yellow)
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol("▶ ");

    f.render_stateful_widget(list, area, &mut app.worn_menu_state.clone());
}

fn render_worn_outfits_list(f: &mut Frame, app: &App, area: Rect) {
    let mode_label = match app.worn_view_mode {
        WornViewMode::Worn => "Worn",
        WornViewMode::Unworn => "Unworn",
    };

    if app.worn_selected_category.is_none() {
        // Show category list
        let items: Vec<ListItem> = app
            .worn_categories
            .iter()
            .map(|name| ListItem::new(format!("📁 {}", name)))
            .collect();

        let title = format!("{} Outfits by Category", mode_label);
        let list = List::new(items)
            .block(Block::default().title(title).borders(Borders::ALL))
            .highlight_style(
                Style::default()
                    .fg(Color::Yellow)
                    .add_modifier(Modifier::BOLD),
            )
            .highlight_symbol("▶ ");

        f.render_stateful_widget(list, area, &mut app.worn_category_state.clone());
    } else {
        // Show outfits for selected category
        let category_name = app.worn_selected_category.as_ref().unwrap();
        let icon = match app.worn_view_mode {
            WornViewMode::Worn => "👔",
            WornViewMode::Unworn => "✨",
        };

        let items: Vec<ListItem> = app
            .worn_outfits_display
            .iter()
            .map(|name| ListItem::new(format!("{} {}", icon, name)))
            .collect();

        let title = format!("{} {} Outfits", category_name, mode_label);
        let list = List::new(items)
            .block(Block::default().title(title).borders(Borders::ALL))
            .highlight_style(
                Style::default()
                    .fg(Color::Yellow)
                    .add_modifier(Modifier::BOLD),
            )
            .highlight_symbol("▶ ");

        f.render_stateful_widget(list, area, &mut app.worn_outfit_state.clone());
    }
}

fn render_settings(f: &mut Frame, app: &App, area: Rect) {
    let config = app.picker.config();
    let text = vec![
        Line::from(vec![
            Span::styled("Root Directory: ", Style::default().fg(Color::Gray)),
            Span::styled(
                config.root.to_string_lossy().to_string(),
                Style::default().fg(Color::White),
            ),
        ]),
        Line::from(vec![
            Span::styled("Language: ", Style::default().fg(Color::Gray)),
            Span::styled(
                config.language.clone().unwrap_or_else(|| "en".to_string()),
                Style::default().fg(Color::White),
            ),
        ]),
        Line::from(vec![
            Span::styled("Excluded Categories: ", Style::default().fg(Color::Gray)),
            Span::styled(
                if config.excluded_categories.is_empty() {
                    "None".to_string()
                } else {
                    config.excluded_categories.iter().cloned().collect::<Vec<_>>().join(", ")
                },
                Style::default().fg(Color::White),
            ),
        ]),
    ];

    let paragraph = Paragraph::new(text).block(
        Block::default()
            .title("Settings")
            .borders(Borders::ALL),
    );
    f.render_widget(paragraph, area);
}

fn render_settings_menu(f: &mut Frame, app: &App, area: Rect) {
    let items: Vec<ListItem> = SettingsMenuItem::all()
        .iter()
        .map(|item| {
            let (icon, color) = match item {
                SettingsMenuItem::ChangePath => ("📁", Color::Blue),
                SettingsMenuItem::ChangeLanguage => ("🌐", Color::Cyan),
                SettingsMenuItem::ManageExclusions => ("🚫", Color::Yellow),
                SettingsMenuItem::ResetCategory => ("🔄", Color::Magenta),
                SettingsMenuItem::ResetAll => ("🔄", Color::Red),
                SettingsMenuItem::FactoryReset => ("⚠️", Color::Red),
                SettingsMenuItem::Back => ("◀️", Color::Gray),
            };
            ListItem::new(format!("{} {}", icon, item.label()))
                .style(Style::default().fg(color))
        })
        .collect();

    let list = List::new(items)
        .block(Block::default().title("Settings Menu").borders(Borders::ALL))
        .highlight_style(
            Style::default()
                .fg(Color::Yellow)
                .add_modifier(Modifier::BOLD)
                .add_modifier(Modifier::REVERSED),
        )
        .highlight_symbol("▶ ");

    f.render_stateful_widget(list, area, &mut app.settings_menu_state.clone());
}

fn render_edit_path(f: &mut Frame, app: &App, area: Rect) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),  // Title
            Constraint::Length(5),  // Input box
            Constraint::Length(3),  // Current value
            Constraint::Min(0),     // Padding
        ])
        .split(area);

    // Title
    let title = Paragraph::new("Enter the path to your outfits folder:")
        .style(Style::default().fg(Color::Cyan))
        .block(Block::default().borders(Borders::ALL));
    f.render_widget(title, chunks[0]);

    // Input field with cursor
    let input_text = app.input_buffer.clone();
    let cursor_pos = app.input_cursor;
    
    // Create a visual cursor in the input
    let display_text = if cursor_pos <= input_text.len() {
        format!("{}│{}", &input_text[..cursor_pos], &input_text[cursor_pos..])
    } else {
        format!("{}│", input_text)
    };
    
    let input = Paragraph::new(display_text)
        .style(Style::default().fg(Color::White))
        .block(
            Block::default()
                .title("Path")
                .borders(Borders::ALL)
                .border_style(Style::default().fg(Color::Yellow)),
        );
    f.render_widget(input, chunks[1]);

    // Current value
    let current = Paragraph::new(format!(
        "Current: {}",
        app.picker.config().root.to_string_lossy()
    ))
    .style(Style::default().fg(Color::Gray))
    .block(Block::default().borders(Borders::ALL));
    f.render_widget(current, chunks[2]);
}

fn render_edit_language(f: &mut Frame, app: &App, area: Rect) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),  // Title
            Constraint::Length(5),  // Input box
            Constraint::Length(5),  // Current + hint
            Constraint::Min(0),     // Padding
        ])
        .split(area);

    // Title
    let title = Paragraph::new("Enter language code (2 letters, e.g., en, de, fr):")
        .style(Style::default().fg(Color::Cyan))
        .block(Block::default().borders(Borders::ALL));
    f.render_widget(title, chunks[0]);

    // Input field with cursor
    let input_text = app.input_buffer.clone();
    let cursor_pos = app.input_cursor;
    
    let display_text = if cursor_pos <= input_text.len() {
        format!("{}│{}", &input_text[..cursor_pos], &input_text[cursor_pos..])
    } else {
        format!("{}│", input_text)
    };
    
    let input = Paragraph::new(display_text)
        .style(Style::default().fg(Color::White))
        .block(
            Block::default()
                .title("Language")
                .borders(Borders::ALL)
                .border_style(Style::default().fg(Color::Yellow)),
        );
    f.render_widget(input, chunks[1]);

    // Current value and hint
    let current_lang = app.picker.config().language.clone().unwrap_or_else(|| "en".to_string());
    let hint = Paragraph::new(vec![
        Line::from(format!("Current: {}", current_lang)),
        Line::from("Examples: en, de, fr, es, it, ja"),
    ])
    .style(Style::default().fg(Color::Gray))
    .block(Block::default().borders(Borders::ALL));
    f.render_widget(hint, chunks[2]);
}

fn render_edit_exclusions(f: &mut Frame, app: &App, area: Rect) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),  // Title
            Constraint::Length(5),  // Input box
            Constraint::Length(5),  // Current + hint
            Constraint::Min(0),     // Padding
        ])
        .split(area);

    // Title
    let title = Paragraph::new("Enter excluded categories (comma-separated):")
        .style(Style::default().fg(Color::Cyan))
        .block(Block::default().borders(Borders::ALL));
    f.render_widget(title, chunks[0]);

    // Input field with cursor
    let input_text = app.input_buffer.clone();
    let cursor_pos = app.input_cursor;
    
    let display_text = if cursor_pos <= input_text.len() {
        format!("{}│{}", &input_text[..cursor_pos], &input_text[cursor_pos..])
    } else {
        format!("{}│", input_text)
    };
    
    let input = Paragraph::new(display_text)
        .style(Style::default().fg(Color::White))
        .block(
            Block::default()
                .title("Exclusions")
                .borders(Borders::ALL)
                .border_style(Style::default().fg(Color::Yellow)),
        );
    f.render_widget(input, chunks[1]);

    // Current value and hint
    let current_exclusions = &app.picker.config().excluded_categories;
    let current_text = if current_exclusions.is_empty() {
        "None".to_string()
    } else {
        current_exclusions.iter().cloned().collect::<Vec<_>>().join(", ")
    };
    let hint = Paragraph::new(vec![
        Line::from(format!("Current: {}", current_text)),
        Line::from("Leave empty to include all categories"),
    ])
    .style(Style::default().fg(Color::Gray))
    .block(Block::default().borders(Borders::ALL));
    f.render_widget(hint, chunks[2]);
}

fn render_first_time_setup(f: &mut Frame, app: &App, area: Rect) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(5),  // Welcome + progress
            Constraint::Length(3),  // Step title
            Constraint::Length(5),  // Input box
            Constraint::Length(4),  // Hint
            Constraint::Min(0),     // Padding
        ])
        .split(area);

    // Welcome and progress
    let step_num = match app.setup_step {
        SetupStep::Path => 1,
        SetupStep::Language => 2,
        SetupStep::Exclusions => 3,
        SetupStep::Complete => 4,
    };
    let welcome = Paragraph::new(vec![
        Line::from(Span::styled(
            "🎽 Welcome to Outfit Picker!",
            Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD),
        )),
        Line::from(""),
        Line::from(format!("Step {} of 3: Let's set up your configuration", step_num)),
    ])
    .block(Block::default().borders(Borders::ALL));
    f.render_widget(welcome, chunks[0]);

    match app.setup_step {
        SetupStep::Path => {
            let title = Paragraph::new("📁 Where are your outfits stored?")
                .style(Style::default().fg(Color::Yellow))
                .block(Block::default().borders(Borders::ALL));
            f.render_widget(title, chunks[1]);

            // Input field
            let input_text = app.input_buffer.clone();
            let cursor_pos = app.input_cursor;
            let display_text = if cursor_pos <= input_text.len() {
                format!("{}│{}", &input_text[..cursor_pos], &input_text[cursor_pos..])
            } else {
                format!("{}│", input_text)
            };
            
            let input = Paragraph::new(display_text)
                .style(Style::default().fg(Color::White))
                .block(
                    Block::default()
                        .title("Path")
                        .borders(Borders::ALL)
                        .border_style(Style::default().fg(Color::Yellow)),
                );
            f.render_widget(input, chunks[2]);

            let hint = Paragraph::new("Enter the full path to your outfits folder")
                .style(Style::default().fg(Color::Gray))
                .block(Block::default().borders(Borders::ALL));
            f.render_widget(hint, chunks[3]);
        }
        SetupStep::Language => {
            let title = Paragraph::new("🌐 What language for avatar file matching?")
                .style(Style::default().fg(Color::Yellow))
                .block(Block::default().borders(Borders::ALL));
            f.render_widget(title, chunks[1]);

            // Input field
            let input_text = app.input_buffer.clone();
            let cursor_pos = app.input_cursor;
            let display_text = if cursor_pos <= input_text.len() {
                format!("{}│{}", &input_text[..cursor_pos], &input_text[cursor_pos..])
            } else {
                format!("{}│", input_text)
            };
            
            let input = Paragraph::new(display_text)
                .style(Style::default().fg(Color::White))
                .block(
                    Block::default()
                        .title("Language")
                        .borders(Borders::ALL)
                        .border_style(Style::default().fg(Color::Yellow)),
                );
            f.render_widget(input, chunks[2]);

            let hint = Paragraph::new("2-letter code (en, de, fr, etc.) - Press Tab to skip (defaults to en)")
                .style(Style::default().fg(Color::Gray))
                .block(Block::default().borders(Borders::ALL));
            f.render_widget(hint, chunks[3]);
        }
        SetupStep::Exclusions => {
            let title = Paragraph::new("🚫 Any categories to exclude?")
                .style(Style::default().fg(Color::Yellow))
                .block(Block::default().borders(Borders::ALL));
            f.render_widget(title, chunks[1]);

            // Input field
            let input_text = app.input_buffer.clone();
            let cursor_pos = app.input_cursor;
            let display_text = if cursor_pos <= input_text.len() {
                format!("{}│{}", &input_text[..cursor_pos], &input_text[cursor_pos..])
            } else {
                format!("{}│", input_text)
            };
            
            let input = Paragraph::new(display_text)
                .style(Style::default().fg(Color::White))
                .block(
                    Block::default()
                        .title("Exclusions")
                        .borders(Borders::ALL)
                        .border_style(Style::default().fg(Color::Yellow)),
                );
            f.render_widget(input, chunks[2]);

            let hint = Paragraph::new("Comma-separated list - Press Tab/Enter to skip")
                .style(Style::default().fg(Color::Gray))
                .block(Block::default().borders(Borders::ALL));
            f.render_widget(hint, chunks[3]);
        }
        SetupStep::Complete => {
            let complete = Paragraph::new(vec![
                Line::from(""),
                Line::from(Span::styled(
                    "🎉 Setup Complete!",
                    Style::default().fg(Color::Green).add_modifier(Modifier::BOLD),
                )),
                Line::from(""),
                Line::from("Press Enter to start using Outfit Picker"),
            ])
            .alignment(ratatui::layout::Alignment::Center)
            .block(Block::default().borders(Borders::ALL));
            f.render_widget(complete, chunks[1]);
        }
    }
}

fn render_help(f: &mut Frame, area: Rect) {
    let text = vec![
        Line::from(""),
        Line::from(vec![
            Span::styled("↑/k     ", Style::default().fg(Color::Yellow)),
            Span::raw("Move up"),
        ]),
        Line::from(vec![
            Span::styled("↓/j     ", Style::default().fg(Color::Yellow)),
            Span::raw("Move down"),
        ]),
        Line::from(vec![
            Span::styled("Enter   ", Style::default().fg(Color::Yellow)),
            Span::raw("Select/Confirm"),
        ]),
        Line::from(vec![
            Span::styled("s       ", Style::default().fg(Color::Yellow)),
            Span::raw("Skip outfit (session only)"),
        ]),
        Line::from(vec![
            Span::styled("r       ", Style::default().fg(Color::Yellow)),
            Span::raw("Reset (rotation on category list, session on detail)"),
        ]),
        Line::from(vec![
            Span::styled("p       ", Style::default().fg(Color::Yellow)),
            Span::raw("Pick random from category"),
        ]),
        Line::from(vec![
            Span::styled("Esc     ", Style::default().fg(Color::Yellow)),
            Span::raw("Go back"),
        ]),
        Line::from(vec![
            Span::styled("q       ", Style::default().fg(Color::Yellow)),
            Span::raw("Quit"),
        ]),
        Line::from(vec![
            Span::styled("?       ", Style::default().fg(Color::Yellow)),
            Span::raw("Show this help"),
        ]),
        Line::from(""),
        Line::from(Span::styled(
            "Press Esc to return",
            Style::default().fg(Color::Gray),
        )),
    ];

    let paragraph = Paragraph::new(text).block(
        Block::default()
            .title("Help")
            .borders(Borders::ALL),
    );
    f.render_widget(paragraph, area);
}
