//! Use cases for the outfit picker application.
//!
//! This module contains the business logic use cases following Clean Architecture.

pub mod get_categories;
pub mod reset_category;
pub mod select_outfit;
pub mod wear_outfit;

#[cfg(test)]
mod tests;

pub use get_categories::GetCategoriesUseCase;
pub use reset_category::ResetCategoryUseCase;
pub use select_outfit::SelectOutfitUseCase;
pub use wear_outfit::WearOutfitUseCase;
