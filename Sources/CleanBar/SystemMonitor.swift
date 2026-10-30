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
    
    public var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(usedBytes), countStyle: .memory)
    }
    public var freeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(freeBytes), countStyle: .memory)
    }
    public var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .memory)
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
            return MemoryInfo(totalBytes: totalMem, usedBytes: usedMem, freeBytes: freeMem)
        }
        
        return MemoryInfo(totalBytes: totalMem, usedBytes: 0, freeBytes: totalMem)
    }
    
    public func emptyTrash(completion: @escaping @Sendable (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let home = NSHomeDirectory()
            let trashPath = (home as NSString).appendingPathComponent(".Trash")
            let fm = FileManager.default
            var success = true
            
            if let items = try? fm.contentsOfDirectory(atPath: trashPath) {
                for item in items {
                    let p = (trashPath as NSString).appendingPathComponent(item)
                    do {
                        try fm.removeItem(atPath: p)
                    } catch {
                        success = false
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(success)
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
