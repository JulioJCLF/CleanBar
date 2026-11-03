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
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        ProcessInfo.processInfo.disableAutomaticTermination("CleanBar Active")
        ProcessInfo.processInfo.disableSuddenTermination()
        
        // Setup standard macOS Application Menus
        setupMainMenu()
        
        // Status bar item setup
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
        
        // Update Menubar Button
        updateButtonTitle()
        
        // Configure Dock policy and open Main Window on launch
        NSApp.setActivationPolicy(.regular)
        
        // Check if launched with background flag
        let isBackground = CommandLine.arguments.contains("--background")
        if !isBackground {
            showMainWindow()
        }
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }
    
    public func applicationDidBecomeActive(_ notification: Notification) {
        PermissionsManager.shared.checkPermissions()
    }
    
    // MARK: - Window Management
    
    public func showMainWindow() {
        MainWindowController.shared.showWindow()
    }
    
    public func closeMainWindow() {
        MainWindowController.shared.closeWindow()
    }
    
    public func toggleMainWindow() {
        MainWindowController.shared.toggleWindow()
    }
    
    // MARK: - Status Bar Actions
    
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
        
        // Refresh lightweight syscalls (< 0.1ms) strictly on opening
        AppState.shared.refreshDisk()
        AppState.shared.refreshMemory()
        updateButtonTitle()
        
        if AppState.shared.selectedTab == .processes {
            AppState.shared.refreshProcesses()
        }
        if AppState.shared.selectedTab == .deepClean && AppState.shared.deepCleanCategories.isEmpty {
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
        AppState.shared.purgeTransientMemory()
    }
    
    // MARK: - Event Monitors (Click Outside & ESC)
    
    private func setupEventMonitors() {
        removeEventMonitors()
        
        // Closes popover whenever the user clicks anywhere outside of CleanBar's window
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            guard let self = self else { return }
            
            // If user clicked the status bar button itself, allow statusBarButtonClicked to toggle smoothly
            if let button = self.statusItem.button, let window = button.window {
                let mouseScreen = NSEvent.mouseLocation
                if window.frame.contains(mouseScreen) {
                    return
                }
            }
            
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
        let isEn = AppState.shared.language == .english
        
        let headerItem = NSMenuItem(title: "✨ CleanBar v1.1.0", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let openWindowItem = NSMenuItem(
            title: isEn ? "Open CleanBar App" : "Abrir CleanBar App",
            action: #selector(menuOpenWindowClicked),
            keyEquivalent: "o"
        )
        openWindowItem.target = self
        menu.addItem(openWindowItem)
        
        let openPopoverItem = NSMenuItem(
            title: isEn ? "Menu Bar Panel" : "Painel da Barra de Menus",
            action: #selector(menuOpenPopoverClicked),
            keyEquivalent: "p"
        )
        openPopoverItem.target = self
        menu.addItem(openPopoverItem)
        
        let refreshItem = NSMenuItem(
            title: isEn ? "Refresh Metrics" : "Atualizar Métricas",
            action: #selector(menuRefreshClicked),
            keyEquivalent: "r"
        )
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: isEn ? "Quit CleanBar" : "Sair do CleanBar",
            action: #selector(menuQuitClicked),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        sender.performClick(nil)
        statusItem.menu = nil // reset so left click still triggers action
    }
    
    @objc private func menuOpenWindowClicked() {
        showMainWindow()
    }
    
    @objc private func menuOpenPopoverClicked() {
        showPopover()
    }
    
    @objc private func menuRefreshClicked() {
        AppState.shared.refreshDisk()
        AppState.shared.refreshMemory()
        AppState.shared.refreshProcesses()
        updateButtonTitle()
    }
    
    @objc private func menuQuitClicked() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Application Main Menu
    
    public func setupMainMenu() {
        let mainMenu = NSMenu()
        let isEn = AppState.shared.language == .english
        
        // 1. CleanBar App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "CleanBar")
        
        appMenu.addItem(withTitle: isEn ? "About CleanBar" : "Sobre o CleanBar", action: #selector(menuAboutClicked), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        
        let prefsItem = NSMenuItem(title: isEn ? "Preferences..." : "Preferências...", action: #selector(menuPreferencesClicked), keyEquivalent: ",")
        prefsItem.target = self
        appMenu.addItem(prefsItem)
        appMenu.addItem(NSMenuItem.separator())
        
        appMenu.addItem(withTitle: isEn ? "Hide CleanBar" : "Ocultar CleanBar", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: isEn ? "Hide Others" : "Ocultar Outros", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(withTitle: isEn ? "Show All" : "Mostrar Tudo", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: isEn ? "Quit CleanBar" : "Sair do CleanBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // 2. Actions Menu
        let actionsMenuItem = NSMenuItem()
        let actionsMenu = NSMenu(title: isEn ? "Actions" : "Ações")
        
        let refreshAction = NSMenuItem(title: isEn ? "Refresh Metrics" : "Atualizar Métricas", action: #selector(menuRefreshClicked), keyEquivalent: "r")
        refreshAction.target = self
        actionsMenu.addItem(refreshAction)
        
        let quickCleanAction = NSMenuItem(title: isEn ? "1-Click Optimization" : "Otimização com 1 Clique", action: #selector(menuOneClickOptimize), keyEquivalent: "k")
        quickCleanAction.target = self
        actionsMenu.addItem(quickCleanAction)
        
        actionsMenu.addItem(NSMenuItem.separator())
        actionsMenu.addItem(withTitle: isEn ? "Close Window" : "Fechar Janela", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        actionsMenuItem.submenu = actionsMenu
        mainMenu.addItem(actionsMenuItem)
        
        // 3. View Menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: isEn ? "View" : "Visualizar")
        
        let tab1 = NSMenuItem(title: isEn ? "Overview" : "Visão Geral", action: #selector(menuSelectDashboard), keyEquivalent: "1")
        tab1.target = self
        viewMenu.addItem(tab1)
        
        let tab2 = NSMenuItem(title: isEn ? "Deep Clean" : "Limpeza Profunda", action: #selector(menuSelectDeepClean), keyEquivalent: "2")
        tab2.target = self
        viewMenu.addItem(tab2)
        
        let tab3 = NSMenuItem(title: isEn ? "Processes & CPU" : "Processos & CPU", action: #selector(menuSelectProcesses), keyEquivalent: "3")
        tab3.target = self
        viewMenu.addItem(tab3)
        
        let tab4 = NSMenuItem(title: isEn ? "Maintenance" : "Manutenção", action: #selector(menuSelectQuickTools), keyEquivalent: "4")
        tab4.target = self
        viewMenu.addItem(tab4)
        
        let tab5 = NSMenuItem(title: isEn ? "Settings" : "Configurações", action: #selector(menuSelectSettings), keyEquivalent: "5")
        tab5.target = self
        viewMenu.addItem(tab5)
        
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)
        
        // 4. Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: isEn ? "Window" : "Janela")
        windowMenu.addItem(withTitle: isEn ? "Minimize" : "Minimizar", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: isEn ? "Bring All to Front" : "Trazer Todas para a Frente", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        
        NSApp.mainMenu = mainMenu
    }
    
    @objc private func menuAboutClicked() {
        showMainWindow()
        AppState.shared.selectedTab = .settings
    }
    
    @objc private func menuPreferencesClicked() {
        showMainWindow()
        AppState.shared.selectedTab = .settings
    }
    
    @objc private func menuOneClickOptimize() {
        AppState.shared.oneClickOptimize()
    }
    
    @objc private func menuSelectDashboard() {
        showMainWindow()
        AppState.shared.selectedTab = .dashboard
    }
    
    @objc private func menuSelectDeepClean() {
        showMainWindow()
        AppState.shared.selectedTab = .deepClean
    }
    
    @objc private func menuSelectProcesses() {
        showMainWindow()
        AppState.shared.selectedTab = .processes
    }
    
    @objc private func menuSelectQuickTools() {
        showMainWindow()
        AppState.shared.selectedTab = .quickTools
    }
    
    @objc private func menuSelectSettings() {
        showMainWindow()
        AppState.shared.selectedTab = .settings
    }
    
    // MARK: - Menubar Status Title
    
    public func updateButtonTitle() {
        guard let button = statusItem.button else { return }
        if AppState.shared.showDiskInMenubar {
            let disk = SystemMonitor.shared.getDiskSpace()
            button.title = " \(disk.freeFormatted)"
        } else {
            button.title = ""
        }
    }
}
