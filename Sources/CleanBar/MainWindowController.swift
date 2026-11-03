import Cocoa
import AppKit
import SwiftUI

@MainActor
public final class MainWindowController: NSObject, NSWindowDelegate {
    public static let shared = MainWindowController()
    
    private var window: NSWindow?
    
    public override init() {
        super.init()
    }
    
    public func showWindow() {
        if window == nil {
            createWindow()
        }
        
        guard let window = self.window else { return }
        
        // Force regular activation so Dock icon and window appear front and center
        NSApp.setActivationPolicy(.regular)
        
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func closeWindow() {
        window?.performClose(nil)
    }
    
    public func toggleWindow() {
        if let window = window, window.isVisible, window.isKeyWindow {
            window.performClose(nil)
        } else {
            showWindow()
        }
    }
    
    public var isWindowVisible: Bool {
        window?.isVisible ?? false
    }
    
    private func createWindow() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 880, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        win.center()
        win.minSize = NSSize(width: 820, height: 560)
        win.title = "CleanBar"
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isMovableByWindowBackground = true
        win.isReleasedWhenClosed = false
        win.setFrameAutosaveName("CleanBarMainWindow")
        
        // Set standard background color for window
        win.backgroundColor = NSColor.windowBackgroundColor
        
        // Use NSHostingController so SwiftUI view is properly attached and sized
        let hostingController = NSHostingController(rootView: CleanBarMainWindowView())
        win.contentViewController = hostingController
        win.delegate = self
        
        self.window = win
    }
    
    // MARK: - NSWindowDelegate
    
    public func windowWillClose(_ notification: Notification) {
        // If user preference specifies accessory mode when window is closed, revert policy
        if !AppState.shared.keepInDock {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
