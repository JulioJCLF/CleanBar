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
        
        // 1. App Caches
        let appCacheSize = calculateAppCacheSize()
        categories.append(CleanCategoryItem(
            key: "app_caches",
            title: "Caches de Aplicativos",
            icon: "shippingbox",
            subtitle: "Navegadores, Spotify, Dia e ferramentas em ~/Library/Caches",
            estimatedSizeBytes: appCacheSize
        ))
        
        // 2. Build Caches (.next, target)
        let buildCacheSize = calculateBuildCacheSize()
        categories.append(CleanCategoryItem(
            key: "build_caches",
            title: "Caches de Build (.next, target)",
            icon: "hammer",
            subtitle: "Pastas de compilação temporárias em projetos ativos",
            estimatedSizeBytes: buildCacheSize
        ))
        
        // 3. Package Managers (pnpm, npm, brew)
        let packageManagerSize = calculatePackageManagerSize()
        categories.append(CleanCategoryItem(
            key: "pkg_managers",
            title: "Gerenciadores de Pacote",
            icon: "cube.box",
            subtitle: "Pacotes não referenciados do pnpm, npm e fórmulas antigas do brew",
            estimatedSizeBytes: packageManagerSize
        ))
        
        // 4. Logs e Diagnósticos
        let logsSize = calculateLogsSize()
        categories.append(CleanCategoryItem(
            key: "logs",
            title: "Logs e Relatórios Antigos",
            icon: "doc.text",
            subtitle: "Arquivos de log e relatórios em ~/Library/Logs",
            estimatedSizeBytes: logsSize
        ))
        
        return categories
    }
    
    public func performDeepClean(categories: Set<String>, progress: @escaping @Sendable (String) -> Void, completion: @escaping @Sendable (Int64, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var freedBytes: Int64 = 0
            var summary = ""
            
            // 1. App Caches
            if categories.contains("app_caches") {
                progress("Limpando caches de aplicativos...")
                let before = self.calculateAppCacheSize()
                self.cleanAppCaches()
                let after = self.calculateAppCacheSize()
                let freed = max(0, before - after)
                freedBytes += freed
                summary += "Caches de Apps: \(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file))\n"
            }
            
            // 2. Build Caches
            if categories.contains("build_caches") {
                progress("Limpando caches de build (.next, target)...")
                let before = self.calculateBuildCacheSize()
                self.cleanBuildCaches()
                let after = self.calculateBuildCacheSize()
                let freed = max(0, before - after)
                freedBytes += freed
                summary += "Caches de Build: \(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file))\n"
            }
            
            // 3. Package Managers
            if categories.contains("pkg_managers") {
                progress("Podando pnpm, npm e Homebrew...")
                let _ = SystemMonitor.shared.runShellCommand("/Users/jclf/.local/bin/pnpm store prune")
                let _ = SystemMonitor.shared.runShellCommand("npm cache clean --force")
                let _ = SystemMonitor.shared.runShellCommand("/opt/homebrew/bin/brew cleanup -s")
                freedBytes += 200 * 1024 * 1024 // estimate
                summary += "Gerenciadores de Pacotes podados.\n"
            }
            
            // 4. Logs
            if categories.contains("logs") {
                progress("Limpando logs antigos...")
                let before = self.calculateLogsSize()
                self.cleanLogs()
                let after = self.calculateLogsSize()
                let freed = max(0, before - after)
                freedBytes += freed
                summary += "Logs removidos: \(ByteCountFormatter.string(fromByteCount: freed, countStyle: .file))\n"
            }
            
            DispatchQueue.main.async {
                completion(freedBytes, summary)
            }
        }
    }
    
    // MARK: - Calculations
    
    private func calculateAppCacheSize() -> Int64 {
        let targets = [
            "/Users/jclf/Library/Caches/company.thebrowser.dia",
            "/Users/jclf/Library/Caches/Dia",
            "/Users/jclf/Library/Caches/com.spotify.client",
            "/Users/jclf/Library/Caches/Homebrew",
            "/Users/jclf/Library/Caches/pnpm"
        ]
        var total: Int64 = 0
        for target in targets {
            total += fastDirectorySize(target)
        }
        return total
    }
    
    private func calculateBuildCacheSize() -> Int64 {
        let targets = [
            "/Users/jclf/Documents/projects/shopsoft/.next",
            "/Users/jclf/Documents/projects/Crawler/frontend/.next",
            "/Users/jclf/Documents/projects/mac-agent/frontend/.next"
        ]
        var total: Int64 = 0
        for target in targets {
            total += fastDirectorySize(target)
        }
        return total
    }
    
    private func calculatePackageManagerSize() -> Int64 {
        let pnpmStore = "/Users/jclf/Library/pnpm"
        let npmCache = "/Users/jclf/.npm"
        return fastDirectorySize(pnpmStore) + fastDirectorySize(npmCache)
    }
    
    private func calculateLogsSize() -> Int64 {
        return fastDirectorySize("/Users/jclf/Library/Logs")
    }
    
    // MARK: - Cleaners
    
    private func cleanAppCaches() {
        let targets = [
            "/Users/jclf/Library/Caches/company.thebrowser.dia",
            "/Users/jclf/Library/Caches/Dia",
            "/Users/jclf/Library/Caches/com.spotify.client/Data"
        ]
        for t in targets {
            try? FileManager.default.removeItem(atPath: t)
        }
    }
    
    private func cleanBuildCaches() {
        let targets = [
            "/Users/jclf/Documents/projects/shopsoft/.next/cache",
            "/Users/jclf/Documents/projects/Crawler/frontend/.next/cache",
            "/Users/jclf/Documents/projects/mac-agent/frontend/.next/cache"
        ]
        for t in targets {
            try? FileManager.default.removeItem(atPath: t)
        }
    }
    
    private func cleanLogs() {
        let logsDir = "/Users/jclf/Library/Logs"
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: logsDir) else { return }
        for file in files {
            if file.hasPrefix("Claude") || file.hasPrefix("com.openai") || file.hasSuffix(".log") {
                let p = (logsDir as NSString).appendingPathComponent(file)
                try? FileManager.default.removeItem(atPath: p)
            }
        }
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
