import Foundation
import AppKit

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
            
            // CRUCIAL: Always read from pipe BEFORE waiting to exit.
            // In macOS, pipes have a 64KB buffer. If ps produces >64KB and we call waitUntilExit() first,
            // the process blocks forever waiting for the pipe to be drained, causing a permanent deadlock!
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            
            guard let str = String(data: data, encoding: .utf8) else { return [] }
            
            var items: [ProcessInfoItem] = []
            let lines = str.components(separatedBy: "\n").dropFirst() // drop header
            
            for line in lines {
                let parts = line.trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                
                guard parts.count >= 4,
                      let pid = Int(parts[0]),
                      let cpu = Double(parts[1].replacingOccurrences(of: ",", with: ".")),
                      let mem = Double(parts[2].replacingOccurrences(of: ",", with: ".")) else {
                    continue
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
                
                if items.count >= limit { break }
            }
            
            return items
        } catch {
            return []
        }
    }
    
    public func terminateProcess(pid: Int) -> Bool {
        let task = Process()
        task.launchPath = "/bin/kill"
        task.arguments = ["-15", "\(pid)"] // Graceful SIGTERM
        try? task.run()
        task.waitUntilExit()
        
        if task.terminationStatus == 0 {
            return true
        }
        
        // If SIGTERM fails, force with SIGKILL
        let forceTask = Process()
        forceTask.launchPath = "/bin/kill"
        forceTask.arguments = ["-9", "\(pid)"]
        try? forceTask.run()
        forceTask.waitUntilExit()
        return forceTask.terminationStatus == 0
    }
}
