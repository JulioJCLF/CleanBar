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
    
    public func runPackageCacheClean(progress: @escaping @Sendable (String) -> Void, completion: @escaping @Sendable (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var outputLog = ""
            
            progress("Executando pnpm store prune...")
            let pnpmResult = self.runShellCommand("/Users/jclf/.local/bin/pnpm store prune")
            outputLog += "pnpm: \(pnpmResult.trimmingCharacters(in: .whitespacesAndNewlines))\n"
            
            progress("Executando npm cache clean...")
            let npmResult = self.runShellCommand("npm cache clean --force")
            outputLog += "npm: \(npmResult.trimmingCharacters(in: .whitespacesAndNewlines))\n"
            
            progress("Executando brew cleanup...")
            let brewResult = self.runShellCommand("/opt/homebrew/bin/brew cleanup -s")
            outputLog += "brew: \(brewResult.trimmingCharacters(in: .whitespacesAndNewlines))\n"
            
            DispatchQueue.main.async {
                completion(outputLog)
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
        
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/Users/jclf/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Users/jclf/.cargo/bin"
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
