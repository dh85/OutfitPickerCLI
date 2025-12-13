use ratatui::widgets::ListState;
use crate::application::picker::OutfitPicker;
use crate::application::session::OutfitSession;
use crate::domain::models::CategoryInfo;
use super::screens::{Screen, SetupStep, WornViewMode, MainMenuItem, WornMenuItem, SettingsMenuItem};

/// Application state for the TUI.
pub struct App {
    pub picker: OutfitPicker,
    pub session: OutfitSession,
    pub screen: Screen,
    pub main_menu_state: ListState,
    pub category_list_state: ListState,
    pub outfit_list_state: ListState,
    pub worn_menu_state: ListState,
    pub worn_category_state: ListState,
    pub worn_outfit_state: ListState,
    pub settings_menu_state: ListState,
    pub reset_category_state: ListState,
    pub categories: Vec<CategoryInfo>,
    pub current_category_outfits: Vec<String>,
    pub selected_category_index: Option<usize>,
    pub worn_view_mode: WornViewMode,
    pub worn_categories: Vec<String>,
    pub worn_outfits_display: Vec<String>,
    pub worn_selected_category: Option<String>,
    pub message: Option<String>,
    pub should_quit: bool,
    // Input editing state
    pub input_buffer: String,
    pub input_cursor: usize,
    // First-time setup state
    pub setup_step: SetupStep,
    pub is_first_run: bool,
}

impl App {
    pub fn new(picker: OutfitPicker, is_first_run: bool) -> Self {
        let mut main_menu_state = ListState::default();
        main_menu_state.select(Some(0));
        let mut settings_menu_state = ListState::default();
        settings_menu_state.select(Some(0));

        Self {
            picker,
            session: OutfitSession::new(),
            screen: if is_first_run { Screen::FirstTimeSetup } else { Screen::Main },
            main_menu_state,
            category_list_state: ListState::default(),
            outfit_list_state: ListState::default(),
            worn_menu_state: ListState::default(),
            worn_category_state: ListState::default(),
            worn_outfit_state: ListState::default(),
            settings_menu_state,
            reset_category_state: ListState::default(),
            categories: Vec::new(),
            current_category_outfits: Vec::new(),
            selected_category_index: None,
            worn_view_mode: WornViewMode::Worn,
            worn_categories: Vec::new(),
            worn_outfits_display: Vec::new(),
            worn_selected_category: None,
            message: None,
            should_quit: false,
            input_buffer: String::new(),
            input_cursor: 0,
            setup_step: SetupStep::Path,
            is_first_run,
        }
    }

    pub fn next_item(&mut self) {
        match self.screen {
            Screen::Main => {
                let items = MainMenuItem::all();
                let i = match self.main_menu_state.selected() {
                    Some(i) => (i + 1) % items.len(),
                    None => 0,
                };
                self.main_menu_state.select(Some(i));
            }
            Screen::CategoryList => {
                if !self.categories.is_empty() {
                    let i = match self.category_list_state.selected() {
                        Some(i) => (i + 1) % self.categories.len(),
                        None => 0,
                    };
                    self.category_list_state.select(Some(i));
                }
            }
            Screen::CategoryDetail => {
                if !self.current_category_outfits.is_empty() {
                    let i = match self.outfit_list_state.selected() {
                        Some(i) => (i + 1) % self.current_category_outfits.len(),
                        None => 0,
                    };
                    self.outfit_list_state.select(Some(i));
                }
            }
            Screen::WornOutfitsMenu => {
                let items = WornMenuItem::all();
                let i = match self.worn_menu_state.selected() {
                    Some(i) => (i + 1) % items.len(),
                    None => 0,
                };
                self.worn_menu_state.select(Some(i));
            }
            Screen::WornOutfitsList => {
                if self.worn_selected_category.is_none() {
                    // Navigating categories
                    if !self.worn_categories.is_empty() {
                        let i = match self.worn_category_state.selected() {
                            Some(i) => (i + 1) % self.worn_categories.len(),
                            None => 0,
                        };
                        self.worn_category_state.select(Some(i));
                    }
                } else {
                    // Navigating outfits within a category
                    if !self.worn_outfits_display.is_empty() {
                        let i = match self.worn_outfit_state.selected() {
                            Some(i) => (i + 1) % self.worn_outfits_display.len(),
                            None => 0,
                        };
                        self.worn_outfit_state.select(Some(i));
                    }
                }
            }
            Screen::SettingsMenu => {
                let items = SettingsMenuItem::all();
                let i = match self.settings_menu_state.selected() {
                    Some(i) => (i + 1) % items.len(),
                    None => 0,
                };
                self.settings_menu_state.select(Some(i));
            }
            Screen::Settings => {
                // Reset category selection
                if !self.categories.is_empty() {
                    let i = match self.reset_category_state.selected() {
                        Some(i) => (i + 1) % self.categories.len(),
                        None => 0,
                    };
                    self.reset_category_state.select(Some(i));
                }
            }
            _ => {}
        }
    }

    pub fn previous_item(&mut self) {
        match self.screen {
            Screen::Main => {
                let items = MainMenuItem::all();
                let i = match self.main_menu_state.selected() {
                    Some(i) => {
                        if i == 0 {
                            items.len() - 1
                        } else {
                            i - 1
                        }
                    }
                    None => 0,
                };
                self.main_menu_state.select(Some(i));
            }
            Screen::CategoryList => {
                if !self.categories.is_empty() {
                    let i = match self.category_list_state.selected() {
                        Some(i) => {
                            if i == 0 {
                                self.categories.len() - 1
                            } else {
                                i - 1
                            }
                        }
                        None => 0,
                    };
                    self.category_list_state.select(Some(i));
                }
            }
            Screen::CategoryDetail => {
                if !self.current_category_outfits.is_empty() {
                    let i = match self.outfit_list_state.selected() {
                        Some(i) => {
                            if i == 0 {
                                self.current_category_outfits.len() - 1
                            } else {
                                i - 1
                            }
                        }
                        None => 0,
                    };
                    self.outfit_list_state.select(Some(i));
                }
            }
            Screen::WornOutfitsMenu => {
                let items = WornMenuItem::all();
                let i = match self.worn_menu_state.selected() {
                    Some(i) => {
                        if i == 0 {
                            items.len() - 1
                        } else {
                            i - 1
                        }
                    }
                    None => 0,
                };
                self.worn_menu_state.select(Some(i));
            }
            Screen::WornOutfitsList => {
                if self.worn_selected_category.is_none() {
                    // Navigating categories
                    if !self.worn_categories.is_empty() {
                        let i = match self.worn_category_state.selected() {
                            Some(i) => {
                                if i == 0 {
                                    self.worn_categories.len() - 1
                                } else {
                                    i - 1
                                }
                            }
                            None => 0,
                        };
                        self.worn_category_state.select(Some(i));
                    }
                } else {
                    // Navigating outfits within a category
                    if !self.worn_outfits_display.is_empty() {
                        let i = match self.worn_outfit_state.selected() {
                            Some(i) => {
                                if i == 0 {
                                    self.worn_outfits_display.len() - 1
                                } else {
                                    i - 1
                                }
                            }
                            None => 0,
                        };
                        self.worn_outfit_state.select(Some(i));
                    }
                }
            }
            Screen::SettingsMenu => {
                let items = SettingsMenuItem::all();
                let i = match self.settings_menu_state.selected() {
                    Some(i) => {
                        if i == 0 {
                            items.len() - 1
                        } else {
                            i - 1
                        }
                    }
                    None => 0,
                };
                self.settings_menu_state.select(Some(i));
            }
            Screen::Settings => {
                // Reset category selection
                if !self.categories.is_empty() {
                    let i = match self.reset_category_state.selected() {
                        Some(i) => {
                            if i == 0 {
                                self.categories.len() - 1
                            } else {
                                i - 1
                            }
                        }
                        None => 0,
                    };
                    self.reset_category_state.select(Some(i));
                }
            }
            _ => {}
        }
    }

    pub fn go_back(&mut self) {
        match self.screen {
            Screen::CategoryList | Screen::Help | Screen::WornOutfitsMenu | Screen::SettingsMenu => {
                self.screen = Screen::Main;
                self.input_buffer.clear();
                self.input_cursor = 0;
            }
            Screen::Settings | Screen::EditPath | Screen::EditLanguage | Screen::EditExclusions => {
                self.screen = Screen::SettingsMenu;
                self.input_buffer.clear();
                self.input_cursor = 0;
            }
            Screen::CategoryDetail => {
                self.screen = Screen::CategoryList;
            }
            Screen::WornOutfitsList => {
                if self.worn_selected_category.is_some() {
                    // Go back to category list
                    self.worn_selected_category = None;
                    self.worn_outfits_display.clear();
                } else {
                    // Go back to worn menu
                    self.screen = Screen::WornOutfitsMenu;
                }
            }
            Screen::FirstTimeSetup => {
                // Can't go back from setup, just quit
                self.should_quit = true;
            }
            Screen::Main => {
                self.should_quit = true;
            }
        }
        self.message = None;
    }
    
    pub fn handle_char_input(&mut self, c: char) {
        self.input_buffer.insert(self.input_cursor, c);
        self.input_cursor += 1;
    }
    
    pub fn handle_backspace(&mut self) {
        if self.input_cursor > 0 {
            self.input_cursor -= 1;
            self.input_buffer.remove(self.input_cursor);
        }
    }
    
    pub fn handle_delete(&mut self) {
        if self.input_cursor < self.input_buffer.len() {
            self.input_buffer.remove(self.input_cursor);
        }
    }
    
    pub fn move_cursor_left(&mut self) {
        if self.input_cursor > 0 {
            self.input_cursor -= 1;
        }
    }
    
    pub fn move_cursor_right(&mut self) {
        if self.input_cursor < self.input_buffer.len() {
            self.input_cursor += 1;
        }
    }
}
