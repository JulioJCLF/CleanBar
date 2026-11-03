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

public struct MemoryInfo: Sendable {
    public let totalBytes: UInt64
    public let usedBytes: UInt64
    public let freeBytes: UInt64
    public let activeBytes: UInt64
    public let wiredBytes: UInt64
    public let compressedBytes: UInt64
    
    public init(totalBytes: UInt64, usedBytes: UInt64, freeBytes: UInt64, activeBytes: UInt64 = 0, wiredBytes: UInt64 = 0, compressedBytes: UInt64 = 0) {
        self.totalBytes = totalBytes
        self.usedBytes = usedBytes
        self.freeBytes = freeBytes
        self.activeBytes = activeBytes
        self.wiredBytes = wiredBytes
        self.compressedBytes = compressedBytes
    }
    
    public var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(usedBytes), countStyle: .memory)
    }
    public var freeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(freeBytes), countStyle: .memory)
    }
    public var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .memory)
    }
    public var activeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(activeBytes), countStyle: .memory)
    }
    public var wiredFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(wiredBytes), countStyle: .memory)
    }
    public var compressedFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(compressedBytes), countStyle: .memory)
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
    
    public func getMemoryInfo() -> MemoryInfo {
        let totalMem = ProcessInfo.processInfo.physicalMemory
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let kerr = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let active = UInt64(vmStats.active_count) * UInt64(pageSize)
            let wired = UInt64(vmStats.wire_count) * UInt64(pageSize)
            let compressed = UInt64(vmStats.compressor_page_count) * UInt64(pageSize)
            let usedMem = active + wired + compressed
            let freeMem = totalMem > usedMem ? totalMem - usedMem : 0
            return MemoryInfo(
                totalBytes: totalMem,
                usedBytes: usedMem,
                freeBytes: freeMem,
                activeBytes: active,
                wiredBytes: wired,
                compressedBytes: compressed
            )
        }
        
        return MemoryInfo(totalBytes: totalMem, usedBytes: 0, freeBytes: totalMem)
    }
    
    public func flushDNSCache(completion: @escaping @Sendable (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.launchPath = "/usr/bin/dscacheutil"
            task.arguments = ["-flushcache"]
            try? task.run()
            task.waitUntilExit()
            
            let killTask = Process()
            killTask.launchPath = "/usr/bin/killall"
            killTask.arguments = ["-HUP", "mDNSResponder"]
            try? killTask.run()
            killTask.waitUntilExit()
            
            let ok = (task.terminationStatus == 0)
            DispatchQueue.main.async {
                completion(ok)
            }
        }
    }
    
    public var systemUptimeFormatted: String {
        let uptime = ProcessInfo.processInfo.systemUptime
        let days = Int(uptime / 86400)
        let hours = Int((uptime.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((uptime.truncatingRemainder(dividingBy: 3600)) / 60)
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
    
    public var processorFormatted: String {
        #if arch(arm64)
        return "Apple Silicon (ARM64)"
        #elseif arch(x86_64)
        return "Intel (x86_64)"
        #else
        return "Universal"
        #endif
    }
    
    public var osVersionFormatted: String {
        let ver = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(ver.majorVersion).\(ver.minorVersion)"
    }
    
    public func emptyTrash(completion: @escaping @Sendable (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let script = """
            tell application "Finder"
                set trashCount to count every item of trash
                if trashCount > 0 then
                    try
                        empty trash
                        return "emptied:" & trashCount
                    on error errText number errNum
                        return "error:" & errText
                    end try
                else
                    return "already_empty:0"
                end if
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
                
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                DispatchQueue.main.async {
                    if output.hasPrefix("emptied:") {
                        let count = output.replacingOccurrences(of: "emptied:", with: "")
                        completion(true, "Lixeira esvaziada! \(count) item(ns) removido(s).")
                    } else if output.hasPrefix("already_empty:") {
                        completion(true, "A lixeira do macOS já está vazia.")
                    } else if output.hasPrefix("error:") {
                        completion(false, "Aviso ao tentar esvaziar lixeira.")
                    } else {
                        completion(task.terminationStatus == 0, "Lixeira esvaziada com sucesso!")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "Erro ao tentar esvaziar lixeira.")
                }
            }
        }
    }
    
    public func runQuickCacheClean(progress: @escaping @Sendable (String) -> Void, completion: @escaping @Sendable (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            progress("Limpando caches de navegadores e aplicativos...")
            
            let home = NSHomeDirectory()
            let cachesPath = (home as NSString).appendingPathComponent("Library/Caches")
            let fm = FileManager.default
            
            if let items = try? fm.contentsOfDirectory(atPath: cachesPath) {
                for item in items {
                    let lower = item.lowercased()
                    if lower.contains("chrome") || lower.contains("spotify") || lower.contains("slack") ||
                       lower.contains("discord") || lower.contains("arc") || lower.contains("dia") ||
                       lower.contains("firefox") || lower.contains("brave") {
                        let itemPath = (cachesPath as NSString).appendingPathComponent(item)
                        try? fm.removeItem(atPath: itemPath)
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion("Caches de aplicativos e navegadores limpos!")
            }
        }
    }
}
