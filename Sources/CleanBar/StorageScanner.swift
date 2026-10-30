import Foundation
import AppKit

public struct LargeFileItem: Identifiable, Sendable {
    public var id: String { path }
    public let name: String
    public let path: String
    public let sizeBytes: Int64
    public let fileExtension: String
    
    public var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
    
    public var systemIcon: String {
        let ext = fileExtension.lowercased()
        switch ext {
        case "mov", "mp4", "mkv", "avi", "m4v":
            return "film"
        case "dmg", "pkg", "iso":
            return "shippingbox"
        case "zip", "tar", "gz", "7z", "rar":
            return "doc.zipper"
        case "png", "jpg", "jpeg", "heic", "tiff":
            return "photo"
        case "pdf":
            return "doc.richtext"
        default:
            return "doc"
        }
    }
}

public struct StorageFolderBreakdown: Identifiable, Sendable {
    public var id: String { path }
    public let name: String
    public let path: String
    public let sizeBytes: Int64
    public let icon: String
    
    public var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}

public final class StorageScanner: @unchecked Sendable {
    public static let shared = StorageScanner()
    
    private init() {}
    
    private var cachedLargeFiles: [LargeFileItem] = []
    private var cachedBreakdown: [StorageFolderBreakdown] = []
    private var isScanning = false
    private var lastScanTime: Date?
    private let lock = NSLock()
    
    public var largeFiles: [LargeFileItem] {
        lock.lock()
        defer { lock.unlock() }
        return cachedLargeFiles
    }
    
    public var folderBreakdown: [StorageFolderBreakdown] {
        lock.lock()
        defer { lock.unlock() }
        return cachedBreakdown
    }
    
    public var isScanActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isScanning
    }
    
    public func scan(force: Bool = false, completion: @escaping @Sendable ([LargeFileItem], [StorageFolderBreakdown]) -> Void) {
        lock.lock()
        if isScanning {
            let files = cachedLargeFiles
            let breakdown = cachedBreakdown
            lock.unlock()
            completion(files, breakdown)
            return
        }
        
        if !force, let last = lastScanTime, Date().timeIntervalSince(last) < 60 {
            let files = cachedLargeFiles
            let breakdown = cachedBreakdown
            lock.unlock()
            completion(files, breakdown)
            return
        }
        
        isScanning = true
        lock.unlock()
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let files = self.findLargeFiles()
            let breakdown = self.calculateFolderBreakdown()
            
            self.lock.lock()
            self.cachedLargeFiles = files
            self.cachedBreakdown = breakdown
            self.lastScanTime = Date()
            self.isScanning = false
            self.lock.unlock()
            
            completion(files, breakdown)
        }
    }
    
    private func findLargeFiles() -> [LargeFileItem] {
        let home = NSHomeDirectory()
        let fm = FileManager.default
        let searchRoots = [
            (home as NSString).appendingPathComponent("Downloads"),
            (home as NSString).appendingPathComponent("Desktop"),
            (home as NSString).appendingPathComponent("Movies"),
            (home as NSString).appendingPathComponent("Documents"),
            (home as NSString).appendingPathComponent("video")
        ]
        
        var results: [LargeFileItem] = []
        let minSize: Int64 = 40 * 1024 * 1024 // > 40 MB
        
        for root in searchRoots {
            guard fm.fileExists(atPath: root) else { continue }
            guard let enumerator = fm.enumerator(
                at: URL(fileURLWithPath: root),
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }
            
            var countInRoot = 0
            for case let fileURL as URL in enumerator {
                countInRoot += 1
                if countInRoot > 400 { break } // avoid deep traversal
                
                guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                      values.isRegularFile == true,
                      let size = values.fileSize,
                      Int64(size) >= minSize else {
                    continue
                }
                
                results.append(LargeFileItem(
                    name: fileURL.lastPathComponent,
                    path: fileURL.path,
                    sizeBytes: Int64(size),
                    fileExtension: fileURL.pathExtension
                ))
            }
        }
        
        // Sort descending by size and take top 5
        results.sort { $0.sizeBytes > $1.sizeBytes }
        return Array(results.prefix(5))
    }
    
    private func calculateFolderBreakdown() -> [StorageFolderBreakdown] {
        let home = NSHomeDirectory()
        let targets: [(name: String, path: String, icon: String)] = [
            ("Downloads", (home as NSString).appendingPathComponent("Downloads"), "arrow.down.circle"),
            ("Caches de Apps", (home as NSString).appendingPathComponent("Library/Caches"), "shippingbox"),
            ("Documentos", (home as NSString).appendingPathComponent("Documents"), "folder"),
            ("Lixeira", (home as NSString).appendingPathComponent(".Trash"), "trash")
        ]
        
        var breakdown: [StorageFolderBreakdown] = []
        for target in targets {
            let size = fastDirectorySize(target.path)
            breakdown.append(StorageFolderBreakdown(
                name: target.name,
                path: target.path,
                sizeBytes: size,
                icon: target.icon
            ))
        }
        return breakdown
    }
    
    public func trashFile(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            return true
        } catch {
            return false
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
