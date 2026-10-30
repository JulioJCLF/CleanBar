import Foundation
import AppKit
import Darwin

public struct DiskSpaceInfo: Sendable {
    public let totalBytes: Int64
    public let freeBytes: Int64
    public let usedBytes: Int64
    
    public var freeFormatted: String {
        ByteCountFormatter.string(fromByteCount: freeBytes, countStyle: .file)
    }
    
    public var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    public var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: usedBytes, countStyle: .file)
    }
    
    public var percentUsed: Int {
        guard totalBytes > 0 else { return 0 }
        return Int((Double(usedBytes) / Double(totalBytes)) * 100.0)
    }
}

public final class SystemMonitor: @unchecked Sendable {
    public static let shared = SystemMonitor()
    
    private init() {}
    
    public func getDiskSpace() -> DiskSpaceInfo {
        var stat = statfs()
        if statfs("/", &stat) == 0 {
            let total = Int64(stat.f_blocks) * Int64(stat.f_bsize)
            let free = Int64(stat.f_bavail) * Int64(stat.f_bsize)
            let used = max(0, total - free)
            return DiskSpaceInfo(totalBytes: total, freeBytes: free, usedBytes: used)
        }
        return DiskSpaceInfo(totalBytes: 0, freeBytes: 0, usedBytes: 0)
    }
    
    public func emptyTrash(completion: @escaping @Sendable (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let script = "tell application \"Finder\" to empty trash"
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
                DispatchQueue.main.async {
                    completion(error == nil)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    public func runQuickCacheClean(progress: @escaping @Sendable (String) -> Void, completion: @escaping @Sendable (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            progress("Limpando caches de navegação e temporários...")
            
            let home = NSHomeDirectory()
            let cachesPath = (home as NSString).appendingPathComponent("Library/Caches")
            let fm = FileManager.default
            
            var clearedItems = 0
            if let items = try? fm.contentsOfDirectory(atPath: cachesPath) {
                for item in items {
                    // Safe browser and common app caches
                    let lower = item.lowercased()
                    if lower.contains("chrome") || lower.contains("spotify") || lower.contains("slack") ||
                       lower.contains("discord") || lower.contains("arc") || lower.contains("dia") ||
                       lower.contains("firefox") || lower.contains("brave") {
                        let itemPath = (cachesPath as NSString).appendingPathComponent(item)
                        try? fm.removeItem(atPath: itemPath)
                        clearedItems += 1
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion("Caches de aplicativos e navegadores limpos!")
            }
        }
    }
    
    @discardableResult
    public func runShellCommand(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        
        let home = NSHomeDirectory()
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:\(home)/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        task.environment = env
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Erro: \(error.localizedDescription)"
        }
    }
}
