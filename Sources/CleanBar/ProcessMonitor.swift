import Foundation
import AppKit
import Darwin

public struct ProcessInfoItem: Identifiable, Sendable {
    public var id: Int { pid }
    public let pid: Int
    public let name: String
    public let cpuPercent: Double
    public let memPercent: Double
    public let fullCommand: String
    
    public var isHighCPU: Bool {
        cpuPercent >= 25.0
    }
    
    public var isSystemCritical: Bool {
        let protected = [
            "kernel_task", "launchd", "WindowServer", "loginwindow",
            "opendirectoryd", "diskarbitrationd", "fseventsd", "syslogd",
            "CleanBar"
        ]
        return protected.contains(name) || pid <= 1
    }
}

public final class ProcessMonitor: @unchecked Sendable {
    public static let shared = ProcessMonitor()
    
    private init() {}
    
    public func fetchTopProcesses(limit: Int = 8) -> [ProcessInfoItem] {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        task.arguments = ["-Ao", "pid,%cpu,%mem,comm", "-r"]
        task.launchPath = "/bin/ps"
        
        do {
            try task.run()
            
            // Watchdog guard: kill task if it hangs longer than 1.0 second
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) {
                if task.isRunning {
                    task.terminate()
                }
            }
            
            // Read from pipe before waiting to prevent 64KB pipe buffer deadlocks
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            
            guard let str = String(data: data, encoding: .utf8) else { return [] }
            
            var items: [ProcessInfoItem] = []
            items.reserveCapacity(limit)
            
            // Parse line-by-line in-place without allocating large arrays
            str.enumerateLines { line, stop in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty || trimmed.hasPrefix("PID") { return }
                
                let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
                guard parts.count >= 4,
                      let pid = Int(parts[0]),
                      let cpu = Double(parts[1].replacingOccurrences(of: ",", with: ".")),
                      let mem = Double(parts[2].replacingOccurrences(of: ",", with: ".")) else {
                    return
                }
                
                let commandPath = parts[3...].joined(separator: " ")
                let baseName = (commandPath as NSString).lastPathComponent
                
                items.append(ProcessInfoItem(
                    pid: pid,
                    name: baseName,
                    cpuPercent: cpu,
                    memPercent: mem,
                    fullCommand: commandPath
                ))
                
                if items.count >= limit {
                    stop = true
                }
            }
            
            return items
        } catch {
            return []
        }
    }
    
    public func terminateProcess(pid: Int) -> Bool {
        // Strict security guardrails: prevent killing PID <= 1 (launchd/kernel) or CleanBar itself
        guard pid > 1, pid != Int(getpid()) else { return false }
        
        // Direct Darwin POSIX syscall: 0 subprocesses, 0 pipes, 0 allocations (< 1µs)
        let targetPid = pid_t(pid)
        if Darwin.kill(targetPid, SIGTERM) == 0 {
            return true
        }
        // Force kill with SIGKILL if SIGTERM did not succeed
        return Darwin.kill(targetPid, SIGKILL) == 0
    }
}
