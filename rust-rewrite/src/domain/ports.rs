use async_trait::async_trait;
use std::path::Path;
use std::collections::HashSet;
use crate::domain::models::{CategoryInfo, Config, OutfitCache};
use crate::domain::error::Result;

#[async_trait]
pub trait CategoryScannerPort: Send + Sync {
    async fn scan_categories(&self, root: &Path, excluded: &HashSet<String>) -> Result<Vec<CategoryInfo>>;
}

#[async_trait]
pub trait ConfigRepositoryPort: Send + Sync {
    async fn load(&self) -> Result<Config>;
    async fn save(&self, config: &Config) -> Result<()>;
    async fn delete(&self) -> Result<()>;
    fn exists(&self) -> bool;
}

#[async_trait]
pub trait CacheRepositoryPort: Send + Sync {
    async fn load(&self) -> Result<OutfitCache>;
    async fn save(&self, cache: &OutfitCache) -> Result<()>;
    async fn delete(&self) -> Result<()>;
}
