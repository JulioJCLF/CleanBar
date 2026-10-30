import Cocoa
import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var updateTimer: Timer?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination("CleanBar Active")
        ProcessInfo.processInfo.disableSuddenTermination()
        
        NSApp.setActivationPolicy(.accessory)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "CleanBar")
            button.imagePosition = .imageLeading
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Setup Popover with SwiftUI Glassmorphism View
        popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 490)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: CleanBarView())
        
        updateButtonTitle()
        
        // Refresh disk space in menubar title every 60 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateButtonTitle()
            }
        }
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            AppState.shared.refreshDisk()
            AppState.shared.refreshVideoStatus()
            AppState.shared.refreshProcesses()
            if AppState.shared.selectedTab == .deepClean {
                AppState.shared.scanDeepClean()
            }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    private func updateButtonTitle() {
        let disk = SystemMonitor.shared.getDiskSpace()
        let hasWarning = AppState.shared.hasHighCPUProcess
        
        if hasWarning {
            statusItem.button?.title = " \(disk.freeFormatted) ⚠️"
        } else {
            statusItem.button?.title = " \(disk.freeFormatted)"
        }
    }
}
