import Foundation
import AppKit

public struct VideoFolderStatus: Sendable {
    public let path: String
    public let name: String
    public let totalSizeBytes: Int64
    public let hasWorkCache: Bool
    public let hasLargeMov: Bool
    public let isOptimized: Bool
    
    public var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalSizeBytes, countStyle: .file)
    }
}

public final class VideoJanitor: @unchecked Sendable {
    public static let shared = VideoJanitor()
    
    private init() {}
    
    public let videoDirPath = "/Users/jclf/video"
    public let midiaDirPath = "/Users/jclf/Documents/Midia"
    
    public func scanVideoFolders() -> [VideoFolderStatus] {
        var results: [VideoFolderStatus] = []
        let fileManager = FileManager.default
        let targetDirs = [videoDirPath, midiaDirPath]
        
        for dir in targetDirs {
            guard fileManager.fileExists(atPath: dir) else { continue }
            
            let dirSize = fastDirectorySize(dir)
            let items = (try? fileManager.contentsOfDirectory(atPath: dir)) ?? []
            
            let hasWork = items.contains("work") || items.contains("04_Projeto_Editavel")
            var hasMov = false
            for item in items {
                if item.lowercased().hasSuffix(".mov") {
                    let itemPath = (dir as NSString).appendingPathComponent(item)
                    if let attrs = try? fileManager.attributesOfItem(atPath: itemPath),
                       let size = attrs[.size] as? Int64, size > 200 * 1024 * 1024 {
                        hasMov = true
                        break
                    }
                }
            }
            
            let isClean = !hasWork && !hasMov
            
            results.append(VideoFolderStatus(
                path: dir,
                name: (dir as NSString).lastPathComponent,
                totalSizeBytes: dirSize,
                hasWorkCache: hasWork,
                hasLargeMov: hasMov,
                isOptimized: isClean
            ))
        }
        
        return results
    }
    
    private func fastDirectorySize(_ path: String) -> Int64 {
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
    
    public func cleanVideoDirectory(at path: String, completion: @escaping @Sendable (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let fileManager = FileManager.default
            var log = ""
            
            guard fileManager.fileExists(atPath: path) else {
                DispatchQueue.main.async { completion("Diretório não encontrado: \(path)") }
                return
            }
            
            let items = (try? fileManager.contentsOfDirectory(atPath: path)) ?? []
            var freedBytes: Int64 = 0
            
            for item in items {
                let fullPath = (path as NSString).appendingPathComponent(item)
                var isDir: ObjCBool = false
                
                if fileManager.fileExists(atPath: fullPath, isDirectory: &isDir) {
                    if isDir.boolValue {
                        if item == "work" || item == "04_Projeto_Editavel" || item == ".cache" {
                            let size = self?.fastDirectorySize(fullPath) ?? 0
                            try? fileManager.removeItem(atPath: fullPath)
                            freedBytes += size
                            log += "Removido: \(item) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))\n"
                        }
                    } else {
                        if item.lowercased().hasSuffix(".mov") {
                            let size = (try? fileManager.attributesOfItem(atPath: fullPath)[.size] as? Int64) ?? 0
                            try? fileManager.removeItem(atPath: fullPath)
                            freedBytes += size
                            log += "Removido MOV: \(item) (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file)))\n"
                        }
                    }
                }
            }
            
            let totalFreedFormatted = ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file)
            log += "Total liberado: \(totalFreedFormatted)"
            
            DispatchQueue.main.async {
                completion(log)
            }
        }
    }
}
