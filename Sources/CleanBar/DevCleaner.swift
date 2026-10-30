import Foundation
import AppKit

public struct DevProjectStatus: Identifiable, Sendable {
    public var id: String { path }
    public let name: String
    public let path: String
    public let nodeModulesPath: String?
    public let nodeModulesSizeBytes: Int64
    
    public var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: nodeModulesSizeBytes, countStyle: .file)
    }
}

public final class DevCleaner: @unchecked Sendable {
    public static let shared = DevCleaner()
    
    private init() {}
    
    private let searchDirs = [
        "/Users/jclf/Documents/projects",
        "/Users/jclf/Documents/LcVerum"
    ]
    
    private var cachedProjects: [DevProjectStatus] = []
    private var isScanning = false
    private var lastScanTime: Date?
    private let lock = NSLock()
    
    public var projects: [DevProjectStatus] {
        lock.lock()
        defer { lock.unlock() }
        return cachedProjects
    }
    
    public var isScanActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isScanning
    }
    
    public func triggerManualScan(force: Bool = false, completion: @escaping @Sendable ([DevProjectStatus]) -> Void) {
        lock.lock()
        if isScanning {
            let current = cachedProjects
            lock.unlock()
            completion(current)
            return
        }
        
        // Debounce: 3 minutes unless forced
        if !force, let last = lastScanTime, Date().timeIntervalSince(last) < 180 {
            let current = cachedProjects
            lock.unlock()
            completion(current)
            return
        }
        
        isScanning = true
        lock.unlock()
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let results = self.performScan()
            
            self.lock.lock()
            self.cachedProjects = results
            self.lastScanTime = Date()
            self.isScanning = false
            self.lock.unlock()
            
            completion(results)
        }
    }
    
    private func performScan() -> [DevProjectStatus] {
        var foundProjects: [DevProjectStatus] = []
        let fileManager = FileManager.default
        var visitedPaths = Set<String>()
        
        for searchDir in searchDirs {
            guard fileManager.fileExists(atPath: searchDir) else { continue }
            guard let items = try? fileManager.contentsOfDirectory(atPath: searchDir) else { continue }
            
            for item in items {
                if item.hasPrefix(".") { continue }
                let projectPath = (searchDir as NSString).appendingPathComponent(item)
                let canonicalPath = (try? URL(fileURLWithPath: projectPath).resourceValues(forKeys: [.canonicalPathKey]).canonicalPath) ?? projectPath
                if visitedPaths.contains(canonicalPath) { continue }
                visitedPaths.insert(canonicalPath)
                
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: projectPath, isDirectory: &isDir), isDir.boolValue {
                    let directNodeModules = (projectPath as NSString).appendingPathComponent("node_modules")
                    let webNodeModules = (projectPath as NSString).appendingPathComponent("web/node_modules")
                    let frontendNodeModules = (projectPath as NSString).appendingPathComponent("frontend/node_modules")
                    
                    var targetNodeModules: String? = nil
                    if fileManager.fileExists(atPath: directNodeModules) {
                        targetNodeModules = directNodeModules
                    } else if fileManager.fileExists(atPath: webNodeModules) {
                        targetNodeModules = webNodeModules
                    } else if fileManager.fileExists(atPath: frontendNodeModules) {
                        targetNodeModules = frontendNodeModules
                    }
                    
                    if let nmPath = targetNodeModules {
                        let size = fastDirectorySize(nmPath)
                        if size > 10 * 1024 * 1024 { // > 10 MB
                            foundProjects.append(DevProjectStatus(
                                name: item,
                                path: projectPath,
                                nodeModulesPath: nmPath,
                                nodeModulesSizeBytes: size
                            ))
                        }
                    }
                }
            }
        }
        
        return foundProjects.sorted { $0.nodeModulesSizeBytes > $1.nodeModulesSizeBytes }
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
    
    public func cleanNodeModules(at path: String, completion: @escaping @Sendable (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                if FileManager.default.fileExists(atPath: path) {
                    try FileManager.default.removeItem(atPath: path)
                    self?.triggerManualScan(force: true) { _ in }
                    DispatchQueue.main.async { completion(true) }
                } else {
                    DispatchQueue.main.async { completion(false) }
                }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }
    }
}
