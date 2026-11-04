import Foundation

public struct DevDeduplicationInsight: Sendable {
    public let npmOrYarnProjectCount: Int
    public let pnpmProjectCount: Int
    public let estimatedWastedBytes: Int64
    public let isPnpmInstalled: Bool
    public let pnpmStoreBytes: Int64
    
    public var hasInsight: Bool {
        return npmOrYarnProjectCount > 0
    }
}

public final class DevEnvironmentDetector: Sendable {
    public static let shared = DevEnvironmentDetector()
    
    private init() {}
    
    private var candidateRoots: [String] {
        let home = NSHomeDirectory()
        return [
            (home as NSString).appendingPathComponent("Documents/Projects"),
            (home as NSString).appendingPathComponent("Documents/projects"),
            (home as NSString).appendingPathComponent("Projects"),
            (home as NSString).appendingPathComponent("Developer")
        ]
    }
    
    public func detectInsights() -> DevDeduplicationInsight {
        let fm = FileManager.default
        var npmCount = 0
        var pnpmCount = 0
        var wastedBytes: Int64 = 0
        var checkedProjects = Set<String>()
        
        for root in candidateRoots {
            guard fm.fileExists(atPath: root),
                  let items = try? fm.contentsOfDirectory(atPath: root) else {
                continue
            }
            
            for item in items {
                guard !item.hasPrefix(".") else { continue }
                let projPath = (root as NSString).appendingPathComponent(item)
                
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: projPath, isDirectory: &isDir), isDir.boolValue else { continue }
                
                // Real path to deduplicate symlinks / case variations
                let realProjPath = (projPath as NSString).resolvingSymlinksInPath
                guard !checkedProjects.contains(realProjPath) else { continue }
                checkedProjects.insert(realProjPath)
                
                let check = inspectProject(projPath: projPath, fm: fm)
                if check.isPnpm {
                    pnpmCount += 1
                } else if check.isNpm {
                    npmCount += 1
                    wastedBytes += check.nodeModulesSize
                }
            }
        }
        
        let pnpmPath = resolvePnpmBinary()
        let isPnpmInstalled = pnpmPath != nil
        let pnpmStoreBytes = isPnpmInstalled ? getPnpmStoreSize() : 0
        
        return DevDeduplicationInsight(
            npmOrYarnProjectCount: npmCount,
            pnpmProjectCount: pnpmCount,
            estimatedWastedBytes: wastedBytes,
            isPnpmInstalled: isPnpmInstalled,
            pnpmStoreBytes: pnpmStoreBytes
        )
    }
    
    private func inspectProject(projPath: String, fm: FileManager) -> (isNpm: Bool, isPnpm: Bool, nodeModulesSize: Int64) {
        // Direct root check
        let pnpmLock = (projPath as NSString).appendingPathComponent("pnpm-lock.yaml")
        let npmLock = (projPath as NSString).appendingPathComponent("package-lock.json")
        let yarnLock = (projPath as NSString).appendingPathComponent("yarn.lock")
        let nodeModules = (projPath as NSString).appendingPathComponent("node_modules")
        
        if fm.fileExists(atPath: pnpmLock) {
            return (false, true, 0)
        }
        
        if fm.fileExists(atPath: npmLock) || fm.fileExists(atPath: yarnLock) || fm.fileExists(atPath: nodeModules) {
            let sz = calculateDirectorySize(atPath: nodeModules, fm: fm)
            return (true, false, sz)
        }
        
        // 1-level subfolder inspection (e.g. monorepo / frontend)
        if let subitems = try? fm.contentsOfDirectory(atPath: projPath) {
            for sub in subitems {
                guard !sub.hasPrefix(".") else { continue }
                let subPath = (projPath as NSString).appendingPathComponent(sub)
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: subPath, isDirectory: &isDir), isDir.boolValue else { continue }
                
                let subPnpmLock = (subPath as NSString).appendingPathComponent("pnpm-lock.yaml")
                if fm.fileExists(atPath: subPnpmLock) {
                    return (false, true, 0)
                }
                
                let subNpmLock = (subPath as NSString).appendingPathComponent("package-lock.json")
                let subYarnLock = (subPath as NSString).appendingPathComponent("yarn.lock")
                let subNodeModules = (subPath as NSString).appendingPathComponent("node_modules")
                if fm.fileExists(atPath: subNpmLock) || fm.fileExists(atPath: subYarnLock) || fm.fileExists(atPath: subNodeModules) {
                    let sz = calculateDirectorySize(atPath: subNodeModules, fm: fm)
                    return (true, false, sz)
                }
            }
        }
        
        return (false, false, 0)
    }
    
    private func calculateDirectorySize(atPath path: String, fm: FileManager) -> Int64 {
        guard fm.fileExists(atPath: path) else { return 0 }
        guard let enumerator = fm.enumerator(at: URL(fileURLWithPath: path),
                                             includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey],
                                             options: [.skipsPackageDescendants],
                                             errorHandler: nil) else {
            return 0
        }
        
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let vals = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey]) else {
                continue
            }
            let size = Int64(vals.totalFileAllocatedSize ?? vals.fileAllocatedSize ?? vals.fileSize ?? 0)
            total += size
        }
        return total
    }
    
    private func resolvePnpmBinary() -> String? {
        let home = NSHomeDirectory()
        let paths = [
            "/opt/homebrew/bin/pnpm",
            "/usr/local/bin/pnpm",
            (home as NSString).appendingPathComponent(".local/bin/pnpm"),
            (home as NSString).appendingPathComponent("Library/pnpm/pnpm")
        ]
        let fm = FileManager.default
        for p in paths {
            if fm.isExecutableFile(atPath: p) {
                return p
            }
        }
        return nil
    }
    
    private func getPnpmStoreSize() -> Int64 {
        let home = NSHomeDirectory()
        let storePaths = [
            (home as NSString).appendingPathComponent("Library/pnpm/store"),
            (home as NSString).appendingPathComponent(".local/share/pnpm/store")
        ]
        let fm = FileManager.default
        for p in storePaths {
            if fm.fileExists(atPath: p) {
                return calculateDirectorySize(atPath: p, fm: fm)
            }
        }
        return 0
    }
    
    public func prunePnpmStore(completion: @escaping @Sendable (Bool, String) -> Void) {
        guard let pnpm = resolvePnpmBinary() else {
            completion(false, "pnpm binary not found")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: pnpm)
            task.arguments = ["store", "prune"]
            
            // Environment with standard PATH
            var env = ProcessInfo.processInfo.environment
            let home = NSHomeDirectory()
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:\(home)/.local/bin:/usr/bin:/bin"
            task.environment = env
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            do {
                try task.run()
                task.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                completion(task.terminationStatus == 0, output)
            } catch {
                completion(false, error.localizedDescription)
            }
        }
    }
}
