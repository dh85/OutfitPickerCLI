//! Interactive TUI mode using ratatui.
//!
//! This module provides a terminal user interface for the outfit picker,
//! allowing users to navigate categories and select outfits interactively.

pub mod app;
pub mod events;
pub mod render;
pub mod screens;

use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    Terminal,
};
use std::io;

use crate::domain::error::Result;
use crate::application::picker::OutfitPicker;
use self::app::App;
use self::screens::{Screen, SetupStep};
use self::events::{handle_enter, handle_input_submit, handle_skip, handle_reset, handle_pick_random};
use self::render::ui;

/// Runs the interactive TUI mode.
#[allow(dead_code)]
pub async fn run_interactive(picker: OutfitPicker) -> Result<()> {
    run_interactive_with_setup(picker, false).await
}

/// Runs the interactive TUI mode with optional first-time setup.
pub async fn run_interactive_with_setup(picker: OutfitPicker, is_first_run: bool) -> Result<()> {
    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // Create app state
    let mut app = App::new(picker, is_first_run);

    // Load initial categories (unless first run)
    if !is_first_run {
        app.categories = app.picker.get_categories().await.unwrap_or_default();
        if !app.categories.is_empty() {
            app.category_list_state.select(Some(0));
        }
    }

    // Main loop
    let result = run_app(&mut terminal, &mut app).await;

    // Restore terminal
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    result
}

async fn run_app<B: ratatui::backend::Backend>(
    terminal: &mut Terminal<B>,
    app: &mut App,
) -> Result<()> {
    loop {
        terminal.draw(|f| ui(f, app))?;

        if event::poll(std::time::Duration::from_millis(100))? {
            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Press {
                    // Handle input mode for text editing screens
                    let is_input_screen = matches!(
                        app.screen,
                        Screen::EditPath | Screen::EditLanguage | Screen::EditExclusions | Screen::FirstTimeSetup
                    );
                    
                    if is_input_screen {
                        match key.code {
                            KeyCode::Esc => {
                                app.go_back();
                            }
                            KeyCode::Enter => {
                                handle_input_submit(app).await;
                            }
                            KeyCode::Tab => {
                                // Tab to skip in first-time setup
                                if matches!(app.screen, Screen::FirstTimeSetup) {
                                    match app.setup_step {
                                        SetupStep::Language => {
                                            app.input_buffer.clear();
                                            app.input_cursor = 0;
                                            app.setup_step = SetupStep::Exclusions;
                                        }
                                        SetupStep::Exclusions => {
                                            app.input_buffer.clear();
                                            app.input_cursor = 0;
                                            app.setup_step = SetupStep::Complete;
                                        }
                                        _ => {}
                                    }
                                }
                            }
                            KeyCode::Backspace => {
                                app.handle_backspace();
                            }
                            KeyCode::Delete => {
                                app.handle_delete();
                            }
                            KeyCode::Left => {
                                app.move_cursor_left();
                            }
                            KeyCode::Right => {
                                app.move_cursor_right();
                            }
                            KeyCode::Home => {
                                app.input_cursor = 0;
                            }
                            KeyCode::End => {
                                app.input_cursor = app.input_buffer.len();
                            }
                            KeyCode::Char(c) => {
                                app.handle_char_input(c);
                            }
                            _ => {}
                        }
                    } else {
                        match key.code {
                            KeyCode::Char('q') => {
                                app.should_quit = true;
                            }
                            KeyCode::Esc => {
                                app.go_back();
                            }
                            KeyCode::Up | KeyCode::Char('k') => {
                                app.previous_item();
                            }
                            KeyCode::Down | KeyCode::Char('j') => {
                                app.next_item();
                            }
                            KeyCode::Enter => {
                                handle_enter(app).await;
                            }
                            KeyCode::Char('s') => {
                                handle_skip(app).await;
                            }
                            KeyCode::Char('r') => {
                                handle_reset(app).await;
                            }
                            KeyCode::Char('p') => {
                                handle_pick_random(app).await;
                            }
                            KeyCode::Char('?') => {
                                app.screen = Screen::Help;
                            }
                            _ => {}
                        }
                    }
                }
            }
        }

        if app.should_quit {
            return Ok(());
        }
    }
}
