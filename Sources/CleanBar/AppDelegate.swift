import Cocoa
import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    public static private(set) var shared: AppDelegate?
    
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var globalEventMonitor: Any?
    private var keyEventMonitor: Any?
    private var updateTimer: Timer?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        ProcessInfo.processInfo.disableAutomaticTermination("CleanBar Active")
        ProcessInfo.processInfo.disableSuddenTermination()
        
        NSApp.setActivationPolicy(.accessory)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "CleanBar")
            button.imagePosition = .imageLeading
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Setup Popover with SwiftUI Glassmorphism View
        popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 500)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: CleanBarView())
        
        updateButtonTitle()
        
        // Refresh disk space in menubar title every 60 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateButtonTitle()
            }
        }
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let currentEvent = NSApp.currentEvent else {
            togglePopover()
            return
        }
        
        if currentEvent.type == .rightMouseUp {
            showContextMenu(sender)
        } else {
            togglePopover()
        }
    }
    
    public func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    public func showPopover() {
        guard let button = statusItem.button else { return }
        
        AppState.shared.refreshDisk()
        AppState.shared.refreshStorage()
        AppState.shared.refreshProcesses()
        if AppState.shared.selectedTab == .deepClean {
            AppState.shared.scanDeepClean()
        }
        
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        
        NSApp.activate(ignoringOtherApps: true)
        if let window = popover.contentViewController?.view.window {
            window.makeKeyAndOrderFront(nil)
        }
        
        setupEventMonitors()
    }
    
    public func closePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
        removeEventMonitors()
    }
    
    // MARK: - NSPopoverDelegate
    
    public func popoverDidClose(_ notification: Notification) {
        removeEventMonitors()
    }
    
    // MARK: - Event Monitors (Click Outside & ESC)
    
    private func setupEventMonitors() {
        removeEventMonitors()
        
        // Closes popover whenever the user clicks anywhere outside of CleanBar's window
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if self.popover.isShown {
                    self.closePopover()
                }
            }
        }
        
        // Closes popover whenever the user hits the Escape (ESC) key
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                Task { @MainActor in
                    self?.closePopover()
                }
                return nil
            }
            return event
        }
    }
    
    private func removeEventMonitors() {
        if let gm = globalEventMonitor {
            NSEvent.removeMonitor(gm)
            globalEventMonitor = nil
        }
        if let km = keyEventMonitor {
            NSEvent.removeMonitor(km)
            keyEventMonitor = nil
        }
    }
    
    // MARK: - Context Menu (Right Click)
    
    private func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        
        let headerItem = NSMenuItem(title: "🍏 CleanBar", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let openItem = NSMenuItem(title: "Abrir Painel", action: #selector(menuOpenClicked), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)
        
        let refreshItem = NSMenuItem(title: "Atualizar Status", action: #selector(menuRefreshClicked), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Sair do CleanBar", action: #selector(menuQuitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        sender.performClick(nil)
        statusItem.menu = nil // reset so left click still triggers action
    }
    
    @objc private func menuOpenClicked() {
        showPopover()
    }
    
    @objc private func menuRefreshClicked() {
        AppState.shared.refreshDisk()
        AppState.shared.refreshStorage(force: true)
        AppState.shared.refreshProcesses()
        updateButtonTitle()
    }
    
    @objc private func menuQuitClicked() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Menubar Status Title
    
    public func updateButtonTitle() {
        let disk = SystemMonitor.shared.getDiskSpace()
        let hasWarning = AppState.shared.hasHighCPUProcess
        
        if hasWarning {
            statusItem.button?.title = " \(disk.freeFormatted) ⚠️"
        } else {
            statusItem.button?.title = " \(disk.freeFormatted)"
        }
    }
}
