//! Session-based skip tracking.
//!
//! This module provides tracking for outfits that have been skipped during
//! the current session, so they won't be shown again until the session resets.

use std::collections::{HashMap, HashSet};

/// Tracks skipped outfits within a session.
///
/// This is used to avoid showing the same outfit multiple times when the user
/// presses "skip". The session resets when:
/// - The user selects a different category
/// - The user wears an outfit
/// - The application restarts
#[derive(Debug, Clone, Default)]
pub struct OutfitSession {
    /// Skipped outfits per category (category_name -> set of file_names)
    category_skipped: HashMap<String, HashSet<String>>,
    /// Globally skipped outfits (for cross-category random selection)
    global_skipped: HashSet<String>,
}

impl OutfitSession {
    /// Creates a new empty session.
    pub fn new() -> Self {
        Self::default()
    }

    /// Marks an outfit as skipped in a specific category.
    pub fn skip_in_category(&mut self, category: &str, file_name: &str) {
        self.category_skipped
            .entry(category.to_string())
            .or_default()
            .insert(file_name.to_string());
    }

    /// Marks an outfit as globally skipped (for cross-category selection).
    #[allow(dead_code)]
    pub fn skip_global(&mut self, file_name: &str) {
        self.global_skipped.insert(file_name.to_string());
    }

    /// Checks if an outfit has been skipped in a category.
    #[allow(dead_code)]
    pub fn is_skipped_in_category(&self, category: &str, file_name: &str) -> bool {
        self.category_skipped
            .get(category)
            .map(|set| set.contains(file_name))
            .unwrap_or(false)
    }

    /// Checks if an outfit has been globally skipped.
    #[allow(dead_code)]
    pub fn is_skipped_global(&self, file_name: &str) -> bool {
        self.global_skipped.contains(file_name)
    }

    /// Gets the count of skipped outfits in a category.
    pub fn skipped_count_in_category(&self, category: &str) -> usize {
        self.category_skipped
            .get(category)
            .map(|set| set.len())
            .unwrap_or(0)
    }

    /// Gets the count of globally skipped outfits.
    #[allow(dead_code)]
    pub fn global_skipped_count(&self) -> usize {
        self.global_skipped.len()
    }

    /// Resets skipped outfits for a specific category.
    pub fn reset_category(&mut self, category: &str) {
        self.category_skipped.remove(category);
    }

    /// Resets all globally skipped outfits.
    #[allow(dead_code)]
    pub fn reset_global(&mut self) {
        self.global_skipped.clear();
    }

    /// Resets the entire session.
    pub fn reset_all(&mut self) {
        self.category_skipped.clear();
        self.global_skipped.clear();
    }

    /// Filters a list of file names to exclude skipped ones (category-specific).
    #[allow(dead_code)]
    pub fn filter_category_skipped<'a>(
        &self,
        category: &str,
        file_names: &'a [String],
    ) -> Vec<&'a String> {
        file_names
            .iter()
            .filter(|name| !self.is_skipped_in_category(category, name))
            .collect()
    }

    /// Filters a list of file names to exclude globally skipped ones.
    #[allow(dead_code)]
    pub fn filter_global_skipped<'a>(&self, file_names: &'a [String]) -> Vec<&'a String> {
        file_names
            .iter()
            .filter(|name| !self.is_skipped_global(name))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_new_session_is_empty() {
        let session = OutfitSession::new();
        assert_eq!(session.skipped_count_in_category("any"), 0);
        assert_eq!(session.global_skipped_count(), 0);
    }

    #[test]
    fn test_skip_in_category() {
        let mut session = OutfitSession::new();

        session.skip_in_category("Casual", "outfit1.avatar");
        session.skip_in_category("Casual", "outfit2.avatar");
        session.skip_in_category("Formal", "outfit3.avatar");

        assert!(session.is_skipped_in_category("Casual", "outfit1.avatar"));
        assert!(session.is_skipped_in_category("Casual", "outfit2.avatar"));
        assert!(session.is_skipped_in_category("Formal", "outfit3.avatar"));

        // Not skipped in other category
        assert!(!session.is_skipped_in_category("Formal", "outfit1.avatar"));
        assert!(!session.is_skipped_in_category("Casual", "outfit3.avatar"));

        assert_eq!(session.skipped_count_in_category("Casual"), 2);
        assert_eq!(session.skipped_count_in_category("Formal"), 1);
    }

    #[test]
    fn test_skip_global() {
        let mut session = OutfitSession::new();

        session.skip_global("outfit1.avatar");
        session.skip_global("outfit2.avatar");

        assert!(session.is_skipped_global("outfit1.avatar"));
        assert!(session.is_skipped_global("outfit2.avatar"));
        assert!(!session.is_skipped_global("outfit3.avatar"));

        assert_eq!(session.global_skipped_count(), 2);
    }

    #[test]
    fn test_reset_category() {
        let mut session = OutfitSession::new();

        session.skip_in_category("Casual", "outfit1.avatar");
        session.skip_in_category("Formal", "outfit2.avatar");

        session.reset_category("Casual");

        assert!(!session.is_skipped_in_category("Casual", "outfit1.avatar"));
        assert!(session.is_skipped_in_category("Formal", "outfit2.avatar"));
        assert_eq!(session.skipped_count_in_category("Casual"), 0);
    }

    #[test]
    fn test_reset_global() {
        let mut session = OutfitSession::new();

        session.skip_global("outfit1.avatar");
        session.skip_global("outfit2.avatar");
        session.skip_in_category("Casual", "outfit3.avatar");

        session.reset_global();

        assert!(!session.is_skipped_global("outfit1.avatar"));
        assert!(!session.is_skipped_global("outfit2.avatar"));
        // Category skips are preserved
        assert!(session.is_skipped_in_category("Casual", "outfit3.avatar"));
    }

    #[test]
    fn test_reset_all() {
        let mut session = OutfitSession::new();

        session.skip_global("outfit1.avatar");
        session.skip_in_category("Casual", "outfit2.avatar");

        session.reset_all();

        assert!(!session.is_skipped_global("outfit1.avatar"));
        assert!(!session.is_skipped_in_category("Casual", "outfit2.avatar"));
        assert_eq!(session.global_skipped_count(), 0);
        assert_eq!(session.skipped_count_in_category("Casual"), 0);
    }

    #[test]
    fn test_filter_category_skipped() {
        let mut session = OutfitSession::new();
        session.skip_in_category("Casual", "outfit2.avatar");

        let all_outfits = vec![
            "outfit1.avatar".to_string(),
            "outfit2.avatar".to_string(),
            "outfit3.avatar".to_string(),
        ];

        let filtered = session.filter_category_skipped("Casual", &all_outfits);

        assert_eq!(filtered.len(), 2);
        assert!(filtered.contains(&&"outfit1.avatar".to_string()));
        assert!(filtered.contains(&&"outfit3.avatar".to_string()));
        assert!(!filtered.contains(&&"outfit2.avatar".to_string()));
    }

    #[test]
    fn test_filter_global_skipped() {
        let mut session = OutfitSession::new();
        session.skip_global("outfit1.avatar");
        session.skip_global("outfit3.avatar");

        let all_outfits = vec![
            "outfit1.avatar".to_string(),
            "outfit2.avatar".to_string(),
            "outfit3.avatar".to_string(),
        ];

        let filtered = session.filter_global_skipped(&all_outfits);

        assert_eq!(filtered.len(), 1);
        assert!(filtered.contains(&&"outfit2.avatar".to_string()));
    }

    #[test]
    fn test_skip_same_outfit_twice_is_idempotent() {
        let mut session = OutfitSession::new();

        session.skip_in_category("Casual", "outfit1.avatar");
        session.skip_in_category("Casual", "outfit1.avatar");

        assert_eq!(session.skipped_count_in_category("Casual"), 1);
    }

    #[test]
    fn test_category_and_global_are_independent() {
        let mut session = OutfitSession::new();

        session.skip_in_category("Casual", "outfit1.avatar");
        session.skip_global("outfit1.avatar");

        // Both should report as skipped
        assert!(session.is_skipped_in_category("Casual", "outfit1.avatar"));
        assert!(session.is_skipped_global("outfit1.avatar"));

        // Resetting one doesn't affect the other
        session.reset_category("Casual");
        assert!(!session.is_skipped_in_category("Casual", "outfit1.avatar"));
        assert!(session.is_skipped_global("outfit1.avatar"));
    }

    #[test]
    fn test_empty_filter_returns_all() {
        let session = OutfitSession::new();

        let all_outfits = vec![
            "outfit1.avatar".to_string(),
            "outfit2.avatar".to_string(),
        ];

        let filtered = session.filter_category_skipped("Casual", &all_outfits);
        assert_eq!(filtered.len(), 2);

        let global_filtered = session.filter_global_skipped(&all_outfits);
        assert_eq!(global_filtered.len(), 2);
    }
}
