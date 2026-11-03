import Foundation
import AppKit

@MainActor
public final class PermissionsManager: ObservableObject {
    public static let shared = PermissionsManager()
    
    @Published public var hasFullDiskAccess: Bool = false
    @Published public var hasDownloadsAccess: Bool = false
    
    private init() {
        checkPermissions()
    }
    
    public func checkPermissions() {
        let home = NSHomeDirectory()
        let fm = FileManager.default
        
        // 1. Full Disk Access test (Safari directory is TCC-protected by default on macOS 10.14+)
        let safariPath = (home as NSString).appendingPathComponent("Library/Safari")
        self.hasFullDiskAccess = (try? fm.contentsOfDirectory(atPath: safariPath)) != nil
        
        // 2. Downloads folder test
        let downloadsPath = (home as NSString).appendingPathComponent("Downloads")
        self.hasDownloadsAccess = (try? fm.contentsOfDirectory(atPath: downloadsPath)) != nil
    }
    
    public func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
    
    public func openDownloadsSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Downloads") {
            NSWorkspace.shared.open(url)
        }
    }
    
    public func requestDownloadsAccess() {
        let home = NSHomeDirectory()
        let downloadsPath = (home as NSString).appendingPathComponent("Downloads")
        _ = try? FileManager.default.contentsOfDirectory(atPath: downloadsPath)
        checkPermissions()
    }
    
    public func requestAllPermissions() {
        requestDownloadsAccess()
        openFullDiskAccessSettings()
    }
}
