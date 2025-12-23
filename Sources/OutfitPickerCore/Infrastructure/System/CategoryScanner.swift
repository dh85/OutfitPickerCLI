import Foundation

public struct CategoryScanner: CategoryScannerProtocol {
    private let fileManager: FileManagerProtocol

    public init(
        fileManager: FileManagerProtocol = FileManager.default
    ) {
        self.fileManager = fileManager
    }

    public func scanCategories(in rootPath: String, excludedCategories: Set<String>) async throws
        -> [CategoryInfo]
    {
        return try await ErrorMapper.execute {
            let rootURL = URL(filePath: rootPath, directoryHint: .isDirectory)
            let contents = try fileManager.contentsOfDirectory(
                at: rootURL,
                includingPropertiesForKeys: nil,
                options: []
            )

            let directories = contents.filter { url in
                var isDirectory: ObjCBool = false
                return fileManager.fileExists(
                    atPath: url.path(percentEncoded: false),
                    isDirectory: &isDirectory
                ) && isDirectory.boolValue
            }

            let categoryInfos = try await withThrowingTaskGroup(of: CategoryInfo.self) { group in
                for url in directories {
                    group.addTask {
                        let categoryName = url.lastPathComponent
                        let categoryPath = url.path(percentEncoded: false)
                        let categoryRef = CategoryReference(
                            name: categoryName,
                            path: categoryPath
                        )

                        if excludedCategories.contains(categoryName) {
                            return CategoryInfo(
                                category: categoryRef,
                                state: .userExcluded,
                                outfitCount: 0
                            )
                        }

                        let avatarFiles = try await self.getOutfits(in: categoryPath)
                        let allFiles = try self.fileManager.contentsOfDirectory(
                            at: url,
                            includingPropertiesForKeys: nil,
                            options: []
                        ).filter { !$0.hasDirectoryPath }

                        let state: CategoryState
                        if avatarFiles.isEmpty {
                            state = allFiles.isEmpty ? .empty : .noAvatarFiles
                        } else {
                            state = .hasOutfits
                        }

                        return CategoryInfo(
                            category: categoryRef,
                            state: state,
                            outfitCount: avatarFiles.count
                        )
                    }
                }

                var results: [CategoryInfo] = []
                for try await categoryInfo in group {
                    results.append(categoryInfo)
                }
                return results
            }

            let sortedInfos = categoryInfos.sorted { $0.category.name < $1.category.name }
            return sortedInfos
        }
    }

    public func getOutfits(in categoryPath: String) async throws -> [FileEntry] {
        return try ErrorMapper.execute {
            let url = URL(filePath: categoryPath, directoryHint: .isDirectory)
            let contents = try fileManager.contentsOfDirectory(
                at: url, includingPropertiesForKeys: nil, options: [])
            return BusinessRules.filterOutfitFiles(from: contents)
        }
    }
}
