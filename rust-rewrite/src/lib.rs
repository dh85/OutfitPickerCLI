//! Library exports for the outfit picker.
//!
//! This module re-exports the public API for use as a library.

pub mod application;
pub mod domain;
pub mod infrastructure;
pub mod interface;

#[cfg(test)]
pub mod test_support;

pub use domain::error::{OutfitPickerError, Result};
pub use domain::models::{
    CategoryCache, CategoryInfo, CategoryReference, CategoryState, Config, FileEntry,
    OutfitCache, OutfitSelection,
};
pub use application::picker::OutfitPicker;
pub use application::session::OutfitSession;
pub use application::use_cases::{
    GetCategoriesUseCase, ResetCategoryUseCase, SelectOutfitUseCase, WearOutfitUseCase,
};
