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
        ByteCountFormatter.string(fromByteCount: estimatedSizeBytes, countStyle: .file)
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
                summary += "Caches de Apps: \(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file))\n"
            }
            
            // 2. Installers
            if categories.contains("installers") {
                progress("Removendo instaladores residuais...")
                let before = self.calculateInstallersSize()
                self.cleanInstallers()
                let after = self.calculateInstallersSize()
                let freed = max(0, before - after)
                freedBytes += freed
                summary += "Instaladores: \(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file))\n"
            }
            
            // 3. System Logs
            if categories.contains("system_logs") {
                progress("Limpando logs e relatórios antigos...")
                let before = self.calculateLogsSize()
                self.cleanLogs()
                let after = self.calculateLogsSize()
                let freed = max(0, before - after)
                freedBytes += freed
                summary += "Logs: \(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file))\n"
            }
            
            // 4. Trash & Temp
            if categories.contains("trash_temp") {
                progress("Esvaziando lixeira e temporários...")
                let before = self.calculateTrashSize()
                self.cleanTrashAndTemp()
                let after = self.calculateTrashSize()
                let freed = max(0, before - after)
                freedBytes += freed
                summary += "Lixeira & Temp: \(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file))\n"
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
        let home = NSHomeDirectory()
        let trashPath = (home as NSString).appendingPathComponent(".Trash")
        return fastDirectorySize(trashPath, maxDepth: 2)
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
                let filePath = (downloadsPath as NSString).appendingPathComponent(file)
                try? fm.removeItem(atPath: filePath)
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
        let home = NSHomeDirectory()
        let trashPath = (home as NSString).appendingPathComponent(".Trash")
        let fm = FileManager.default
        
        if let items = try? fm.contentsOfDirectory(atPath: trashPath) {
            for item in items {
                let itemPath = (trashPath as NSString).appendingPathComponent(item)
                try? fm.removeItem(atPath: itemPath)
            }
        }
        
        // Also run Finder empty trash as standard macOS cleanup
        SystemMonitor.shared.emptyTrash { _ in }
    }
    
    // Fast, non-blocking native directory size calculation (Zero child processes, zero pipe deadlock)
    private func fastDirectorySize(_ path: String, maxDepth: Int = 2) -> Int64 {
        let url = URL(fileURLWithPath: path)
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return 0 }
        
        if !isDir.boolValue {
            return (try? fm.attributesOfItem(atPath: path)[.size] as? Int64) ?? 0
        }
        
        var total: Int64 = 0
        if let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsPackageDescendants]
        ) {
            for case let fileURL as URL in enumerator {
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
        return total
    }
}
