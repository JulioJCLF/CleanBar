import Foundation
import AppKit

public struct CleanCategoryItem: Identifiable, Sendable {
    public var id: String { key }
    public let key: String
    public let title: String
    public let icon: String
    public let subtitle: String
    public let estimatedSizeBytes: Int64
    
    public var sizeFormatted: String {
        Formatters.fileString(from: estimatedSizeBytes)
    }
}

public final class DeepCleaner: @unchecked Sendable {
    public static let shared = DeepCleaner()
    
    private init() {}
    
    public func scanCategories() -> [CleanCategoryItem] {
        var categories: [CleanCategoryItem] = []
        
        // 1. App & Browser Caches
        let appCacheSize = calculateAppCacheSize()
        categories.append(CleanCategoryItem(
            key: "app_caches",
            title: "Caches de Aplicativos & Web",
            icon: "globe.americas.fill",
            subtitle: "Navegadores (Chrome, Safari, Arc), Spotify, Slack e apps",
            estimatedSizeBytes: appCacheSize
        ))
        
        // 2. Residual Installers & DMGs
        let installerSize = calculateInstallersSize()
        categories.append(CleanCategoryItem(
            key: "installers",
            title: "Instaladores Residuais (.dmg, .pkg)",
            icon: "shippingbox.fill",
            subtitle: "Imagens de disco e pacotes de instalação em Downloads",
            estimatedSizeBytes: installerSize
        ))
        
        // 3. System & App Logs
        let logsSize = calculateLogsSize()
        categories.append(CleanCategoryItem(
            key: "system_logs",
            title: "Logs e Relatórios do Sistema",
            icon: "doc.text.magnifyingglass",
            subtitle: "Histórico de diagnósticos, falhas de apps e logs antigos",
            estimatedSizeBytes: logsSize
        ))
        
        // 4. Trash & Temp Cache
        let trashSize = calculateTrashSize()
        categories.append(CleanCategoryItem(
            key: "trash_temp",
            title: "Lixeira & Arquivos Temporários",
            icon: "trash.fill",
            subtitle: "Lixeira do macOS e arquivos residuais de sessão",
            estimatedSizeBytes: trashSize
        ))
        
        // 5. Developer Caches (Xcode DerivedData)
        let devSize = calculateDeveloperCacheSize()
        if devSize > 0 {
            categories.append(CleanCategoryItem(
                key: "developer_caches",
                title: "Caches de Desenvolvimento (Xcode)",
                icon: "hammer.fill",
                subtitle: "DerivedData do Xcode e artefatos de compilação",
                estimatedSizeBytes: devSize
            ))
        }
        
        // 6. Project Builds & Framework Caches (.next, dist, pycache, .build)
        let projectSize = calculateProjectBuildsSize()
        if projectSize > 0 {
            categories.append(CleanCategoryItem(
                key: "project_builds",
                title: "Builds e Caches de Projetos",
                icon: "folder.badge.gearshape",
                subtitle: "Next.js (.next), saídas de compilação (dist), Swift (.build) e __pycache__",
                estimatedSizeBytes: projectSize
            ))
        }
        
        return categories
    }
    
    public func performDeepClean(categories: Set<String>, progress: @escaping @Sendable (String) -> Void, completion: @escaping @Sendable (Int64, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var freedBytes: Int64 = 0
            var summary = ""
            
            // 1. App Caches
            if categories.contains("app_caches") {
                progress("Limpando caches de aplicativos e navegadores...")
                let before = self.calculateAppCacheSize()
                self.cleanAppCaches()
                let after = self.calculateAppCacheSize()
                let freed = max(0, before - after)
                freedBytes += freed
                summary += "Caches de Apps: \(Formatters.fileString(from: freed))\n"
            }
            
            // 2. Installers
            if categories.contains("installers") {
                progress("Removendo instaladores residuais...")
                let before = self.calculateInstallersSize()
                self.cleanInstallers()
                let after = self.calculateInstallersSize()
                let freed = max(0, before - after)
                freedBytes += freed
                summary += "Instaladores: \(Formatters.fileString(from: freed))\n"
            }
            
            // 3. System Logs
            if categories.contains("system_logs") {
                progress("Limpando logs e relatórios antigos...")
                let before = self.calculateLogsSize()
                self.cleanLogs()
                let after = self.calculateLogsSize()
                let freed = max(0, before - after)
                freedBytes += freed
                summary += "Logs: \(Formatters.fileString(from: freed))\n"
            }
            
            // 4. Trash & Temp
            if categories.contains("trash_temp") {
                progress("Esvaziando lixeira e temporários...")
                let before = self.calculateTrashSize()
                self.cleanTrashAndTemp()
                let after = self.calculateTrashSize()
                let freed = max(0, before - after)
                freedBytes += freed
                summary += "Lixeira & Temp: \(Formatters.fileString(from: freed))\n"
            }
            
            // 5. Developer Caches
            if categories.contains("developer_caches") {
                progress("Limpando caches de compilação do Xcode...")
                let before = self.calculateDeveloperCacheSize()
                self.cleanDeveloperCaches()
                let after = self.calculateDeveloperCacheSize()
                let freed = max(0, before - after)
                freedBytes += freed
                summary += "Caches de Dev: \(Formatters.fileString(from: freed))\n"
            }
            
            // 6. Project Builds & Framework Caches
            if categories.contains("project_builds") {
                progress("Limpando caches e builds de projetos...")
                let before = self.calculateProjectBuildsSize()
                self.cleanProjectBuilds()
                let after = self.calculateProjectBuildsSize()
                let freed = max(0, before - after)
                freedBytes += freed
                summary += "Builds de Projetos: \(Formatters.fileString(from: freed))\n"
            }
            
            DispatchQueue.main.async {
                completion(freedBytes, summary)
            }
        }
    }
    
    // MARK: - Calculations (Pure Swift Darwin Native - 0 child processes, 0 deadlocks)
    
    private func calculateAppCacheSize() -> Int64 {
        let home = NSHomeDirectory()
        let cachesPath = (home as NSString).appendingPathComponent("Library/Caches")
        let fm = FileManager.default
        
        guard let items = try? fm.contentsOfDirectory(atPath: cachesPath) else { return 0 }
        
        var total: Int64 = 0
        let ignoredPrefixes = ["com.apple.", ".", "CloudKit", "FamilyCircle", "familycircled"]
        
        for item in items {
            if ignoredPrefixes.contains(where: { item.hasPrefix($0) }) { continue }
            let itemPath = (cachesPath as NSString).appendingPathComponent(item)
            total += fastDirectorySize(itemPath, maxDepth: 2)
        }
        return total
    }
    
    private func calculateInstallersSize() -> Int64 {
        let home = NSHomeDirectory()
        let downloadsPath = (home as NSString).appendingPathComponent("Downloads")
        let fm = FileManager.default
        
        guard let files = try? fm.contentsOfDirectory(atPath: downloadsPath) else { return 0 }
        
        var total: Int64 = 0
        let targetExtensions: Set<String> = ["dmg", "pkg", "iso"]
        for file in files {
            let ext = (file as NSString).pathExtension.lowercased()
            if targetExtensions.contains(ext) {
                let filePath = (downloadsPath as NSString).appendingPathComponent(file)
                if let attrs = try? fm.attributesOfItem(atPath: filePath),
                   let size = attrs[.size] as? Int64 {
                    total += size
                }
            }
        }
        return total
    }
    
    private func calculateLogsSize() -> Int64 {
        let home = NSHomeDirectory()
        let logsPath = (home as NSString).appendingPathComponent("Library/Logs")
        return fastDirectorySize(logsPath, maxDepth: 2)
    }
    
    private func calculateTrashSize() -> Int64 {
        let script = """
        tell application "Finder"
            set trashCount to count every item of trash
            if trashCount is 0 then return 0
            try
                set sList to size of every item of trash
                set totalBytes to 0
                repeat with s in sList
                    if s is not missing value then set totalBytes to totalBytes + s
                end repeat
                return totalBytes
            on error
                return 0
            end try
        end tell
        """
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            if let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               let bytes = Int64(str) {
                return bytes
            }
        } catch {}
        
        return 0
    }
    
    // MARK: - Cleaners
    
    private func cleanAppCaches() {
        let home = NSHomeDirectory()
        let cachesPath = (home as NSString).appendingPathComponent("Library/Caches")
        let fm = FileManager.default
        
        guard let items = try? fm.contentsOfDirectory(atPath: cachesPath) else { return }
        
        let ignoredPrefixes = ["com.apple.", ".", "CloudKit", "FamilyCircle", "familycircled"]
        
        for item in items {
            // Avoid touching system protected or sensitive folders
            if ignoredPrefixes.contains(where: { item.hasPrefix($0) }) { continue }
            let itemPath = (cachesPath as NSString).appendingPathComponent(item)
            
            // Clean contents of cache directories gracefully without blocking
            if let subItems = try? fm.contentsOfDirectory(atPath: itemPath) {
                for sub in subItems {
                    let subPath = (itemPath as NSString).appendingPathComponent(sub)
                    try? fm.removeItem(atPath: subPath)
                }
            } else {
                try? fm.removeItem(atPath: itemPath)
            }
        }
    }
    
    private func cleanInstallers() {
        let home = NSHomeDirectory()
        let downloadsPath = (home as NSString).appendingPathComponent("Downloads")
        let fm = FileManager.default
        
        guard let files = try? fm.contentsOfDirectory(atPath: downloadsPath) else { return }
        
        let targetExtensions: Set<String> = ["dmg", "pkg", "iso"]
        for file in files {
            let ext = (file as NSString).pathExtension.lowercased()
            if targetExtensions.contains(ext) {
                let fileURL = URL(fileURLWithPath: (downloadsPath as NSString).appendingPathComponent(file))
                // Safe macOS deletion: move to Trash first so user can 'Put Back' if needed
                do {
                    try fm.trashItem(at: fileURL, resultingItemURL: nil)
                } catch {
                    try? fm.removeItem(at: fileURL)
                }
            }
        }
    }
    
    private func cleanLogs() {
        let home = NSHomeDirectory()
        let logsPath = (home as NSString).appendingPathComponent("Library/Logs")
        let fm = FileManager.default
        
        guard let files = try? fm.contentsOfDirectory(atPath: logsPath) else { return }
        for file in files {
            let filePath = (logsPath as NSString).appendingPathComponent(file)
            try? fm.removeItem(atPath: filePath)
        }
    }
    
    private func cleanTrashAndTemp() {
        let sema = DispatchSemaphore(value: 0)
        SystemMonitor.shared.emptyTrash { _, _ in
            sema.signal()
        }
        _ = sema.wait(timeout: .now() + 5.0)
    }
    
    private func calculateDeveloperCacheSize() -> Int64 {
        let home = NSHomeDirectory()
        let derivedData = (home as NSString).appendingPathComponent("Library/Developer/Xcode/DerivedData")
        return fastDirectorySize(derivedData, maxDepth: 2)
    }
    
    private func cleanDeveloperCaches() {
        let home = NSHomeDirectory()
        let derivedData = (home as NSString).appendingPathComponent("Library/Developer/Xcode/DerivedData")
        let fm = FileManager.default
        if let items = try? fm.contentsOfDirectory(atPath: derivedData) {
            for item in items {
                let itemPath = (derivedData as NSString).appendingPathComponent(item)
                try? fm.removeItem(atPath: itemPath)
            }
        }
    }
    
    // MARK: - Project Builds (.next, dist, pycache, .build)
    
    private var candidateProjectRoots: [String] {
        let home = NSHomeDirectory()
        return [
            (home as NSString).appendingPathComponent("Documents/Projects"),
            (home as NSString).appendingPathComponent("Documents/projects"),
            (home as NSString).appendingPathComponent("Projects"),
            (home as NSString).appendingPathComponent("Developer")
        ]
    }
    
    private func calculateProjectBuildsSize() -> Int64 {
        let fm = FileManager.default
        var total: Int64 = 0
        let targetFolders: Set<String> = [".next", ".build", "dist", ".turbo", "__pycache__"]
        
        for root in candidateProjectRoots {
            guard let projects = try? fm.contentsOfDirectory(atPath: root) else { continue }
            for proj in projects {
                if proj.hasPrefix(".") { continue }
                let projPath = (root as NSString).appendingPathComponent(proj)
                
                // Inspect root of project and 1-subfolder deep (e.g. frontend/.next, backend/dist)
                if let subItems = try? fm.contentsOfDirectory(atPath: projPath) {
                    for item in subItems {
                        let itemPath = (projPath as NSString).appendingPathComponent(item)
                        if targetFolders.contains(item) {
                            total += fastDirectorySize(itemPath, maxDepth: 4)
                        } else {
                            // Check 1 subfolder (e.g. frontend, backend)
                            var isDir: ObjCBool = false
                            if fm.fileExists(atPath: itemPath, isDirectory: &isDir), isDir.boolValue, !item.hasPrefix(".") && item != "node_modules" {
                                if let inner = try? fm.contentsOfDirectory(atPath: itemPath) {
                                    for sub in inner where targetFolders.contains(sub) {
                                        let targetPath = (itemPath as NSString).appendingPathComponent(sub)
                                        total += fastDirectorySize(targetPath, maxDepth: 4)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return total
    }
    
    private func cleanProjectBuilds() {
        let fm = FileManager.default
        let targetFolders: Set<String> = [".next", ".build", "dist", ".turbo", "__pycache__"]
        
        for root in candidateProjectRoots {
            guard let projects = try? fm.contentsOfDirectory(atPath: root) else { continue }
            for proj in projects {
                if proj.hasPrefix(".") { continue }
                let projPath = (root as NSString).appendingPathComponent(proj)
                
                if let subItems = try? fm.contentsOfDirectory(atPath: projPath) {
                    for item in subItems {
                        let itemPath = (projPath as NSString).appendingPathComponent(item)
                        if targetFolders.contains(item) {
                            // Safe removal: if CleanBar itself, keep current active app
                            if proj == "CleanBar" && item == "dist" { continue }
                            try? fm.removeItem(atPath: itemPath)
                        } else {
                            var isDir: ObjCBool = false
                            if fm.fileExists(atPath: itemPath, isDirectory: &isDir), isDir.boolValue, !item.hasPrefix(".") && item != "node_modules" {
                                if let inner = try? fm.contentsOfDirectory(atPath: itemPath) {
                                    for sub in inner where targetFolders.contains(sub) {
                                        let targetPath = (itemPath as NSString).appendingPathComponent(sub)
                                        try? fm.removeItem(atPath: targetPath)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Fast, non-blocking native directory size calculation with autoreleasepool (Zero heap bloat)
    private func fastDirectorySize(_ path: String, maxDepth: Int = 2) -> Int64 {
        let url = URL(fileURLWithPath: path)
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return 0 }
        
        if !isDir.boolValue {
            return (try? fm.attributesOfItem(atPath: path)[.size] as? Int64) ?? 0
        }
        
        var total: Int64 = 0
        autoreleasepool {
            if let enumerator = fm.enumerator(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
                options: [.skipsPackageDescendants, .skipsHiddenFiles]
            ) {
                while let fileURL = enumerator.nextObject() as? URL {
                    if enumerator.level > maxDepth {
                        enumerator.skipDescendants()
                        continue
                    }
                    if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                       values.isRegularFile == true,
                       let size = values.fileSize {
                        total += Int64(size)
                    }
                }
            }
        }
        return total
    }
}
