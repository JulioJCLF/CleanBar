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
    
    // MARK: - Calculations
    
    private func calculateAppCacheSize() -> Int64 {
        let home = NSHomeDirectory()
        let cachesPath = (home as NSString).appendingPathComponent("Library/Caches")
        let fm = FileManager.default
        
        guard let items = try? fm.contentsOfDirectory(atPath: cachesPath) else { return 0 }
        
        var total: Int64 = 0
        for item in items {
            // Include third-party and heavy browser/app caches, skip Apple protected caches
            if item.hasPrefix("com.apple.") { continue }
            let itemPath = (cachesPath as NSString).appendingPathComponent(item)
            total += fastDirectorySize(itemPath)
        }
        return total
    }
    
    private func calculateInstallersSize() -> Int64 {
        let home = NSHomeDirectory()
        let downloadsPath = (home as NSString).appendingPathComponent("Downloads")
        let fm = FileManager.default
        
        guard let files = try? fm.contentsOfDirectory(atPath: downloadsPath) else { return 0 }
        
        var total: Int64 = 0
        for file in files {
            let ext = (file as NSString).pathExtension.lowercased()
            if ext == "dmg" || ext == "pkg" || ext == "iso" {
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
        return fastDirectorySize(logsPath)
    }
    
    private func calculateTrashSize() -> Int64 {
        let home = NSHomeDirectory()
        let trashPath = (home as NSString).appendingPathComponent(".Trash")
        return fastDirectorySize(trashPath)
    }
    
    // MARK: - Cleaners
    
    private func cleanAppCaches() {
        let home = NSHomeDirectory()
        let cachesPath = (home as NSString).appendingPathComponent("Library/Caches")
        let fm = FileManager.default
        
        guard let items = try? fm.contentsOfDirectory(atPath: cachesPath) else { return }
        
        for item in items {
            // Avoid touching system protected com.apple.* to prevent permission dialogs or system locks
            if item.hasPrefix("com.apple.") { continue }
            let itemPath = (cachesPath as NSString).appendingPathComponent(item)
            
            // Clean contents of cache directories
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
        
        for file in files {
            let ext = (file as NSString).pathExtension.lowercased()
            if ext == "dmg" || ext == "pkg" || ext == "iso" {
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
    
    private func fastDirectorySize(_ path: String) -> Int64 {
        guard FileManager.default.fileExists(atPath: path) else { return 0 }
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        task.arguments = ["-sk", path]
        task.launchPath = "/usr/bin/du"
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8),
               let firstPart = output.split(separator: "\t").first,
               let kb = Int64(firstPart.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return kb * 1024
            }
        } catch {
            return 0
        }
        return 0
    }
}
