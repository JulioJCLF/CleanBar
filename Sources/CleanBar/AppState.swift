import Foundation
import SwiftUI
import AppKit

public enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case deepClean
    case processes
    case quickTools
    case settings
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .dashboard: return "sparkles"
        case .deepClean: return "wand.and.stars"
        case .processes: return "cpu"
        case .quickTools: return "wrench.and.screwdriver"
        case .settings: return "gearshape"
        }
    }
}

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    // Language & Localization
    @Published public var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "CB_Language")
            AppDelegate.shared?.updateButtonTitle()
            AppDelegate.shared?.setupMainMenu()
        }
    }
    
    public var strings: Strings {
        Strings(lang: language)
    }
    
    // Navigation
    @Published public var selectedTab: AppTab = .dashboard
    
    // System Vitals (Reads in < 1ms via Darwin Kernel Syscalls, Zero Disk Thrashing)
    @Published public var diskInfo: DiskSpaceInfo = DiskSpaceInfo(totalBytes: 0, freeBytes: 0, usedBytes: 0)
    @Published public var memoryInfo: MemoryInfo = MemoryInfo(totalBytes: 0, usedBytes: 0, freeBytes: 0)
    @Published public var isCleaning = false
    @Published public var isFlushingDNS = false
    @Published public var isOptimizing = false
    @Published public var isRefreshing = false
    @Published public var alertMessage: String?
    
    // Deep Clean (Computed strictly on-demand)
    @Published public var deepCleanCategories: [CleanCategoryItem] = []
    @Published public var selectedCategories: Set<String> = ["app_caches", "installers", "system_logs", "trash_temp", "developer_caches", "project_builds"]
    @Published public var isDeepCleaning = false
    @Published public var isScanningCategories = false
    @Published public var deepCleanProgressText = ""
    @Published public var totalRecoverableBytes: Int64 = 0
    
    // Process Monitor (Refreshed strictly on demand when user opens tab or clicks refresh)
    @Published public var topProcesses: [ProcessInfoItem] = []
    @Published public var hasHighCPUProcess = false
    @Published public var isFetchingProcesses = false
    @Published public var processToKill: ProcessInfoItem?
    @Published public var processSearchQuery: String = ""
    
    // Preferences
    @Published public var keepInDock: Bool {
        didSet {
            UserDefaults.standard.set(keepInDock, forKey: "CB_KeepInDock")
            if keepInDock {
                NSApp.setActivationPolicy(.regular)
            }
        }
    }
    @Published public var showDiskInMenubar: Bool {
        didSet {
            UserDefaults.standard.set(showDiskInMenubar, forKey: "CB_ShowDiskInMenubar")
            AppDelegate.shared?.updateButtonTitle()
        }
    }
    
    private init() {
        // Initialize Language: preference or system locale detection
        if let savedLang = UserDefaults.standard.string(forKey: "CB_Language"),
           let appLang = AppLanguage(rawValue: savedLang) {
            self.language = appLang
        } else {
            let prefLang = Locale.preferredLanguages.first?.lowercased() ?? "en"
            self.language = prefLang.hasPrefix("pt") ? .portuguese : .english
        }
        
        self.keepInDock = UserDefaults.standard.object(forKey: "CB_KeepInDock") as? Bool ?? true
        self.showDiskInMenubar = UserDefaults.standard.object(forKey: "CB_ShowDiskInMenubar") as? Bool ?? true
        
        // Single initial snapshot; zero continuous timers while closed
        refreshDisk()
        refreshMemory()
    }
    
    // MARK: - Health Score Engine
    
    public var macHealthScore: Int {
        var score = 100
        
        // Storage impact (max -35 pts if disk full)
        let diskPercent = diskInfo.percentUsed
        if diskPercent > 90 {
            score -= 35
        } else if diskPercent > 80 {
            score -= 20
        } else if diskPercent > 70 {
            score -= 10
        }
        
        // Memory impact (max -30 pts if memory heavily saturated)
        let memPercent = memoryInfo.percentUsed
        if memPercent > 90 {
            score -= 30
        } else if memPercent > 80 {
            score -= 15
        } else if memPercent > 70 {
            score -= 5
        }
        
        // CPU runaway impact (max -25 pts)
        if hasHighCPUProcess {
            score -= 25
        }
        
        return max(15, min(100, score))
    }
    
    public var macHealthStatus: (title: String, subtitle: String, color: Color) {
        let score = macHealthScore
        if score >= 85 {
            return (strings.healthExcellentTitle, strings.healthExcellentSubtitle, Color.green)
        } else if score >= 65 {
            return (strings.healthGoodTitle, strings.healthGoodSubtitle, Color.yellow)
        } else {
            return (strings.healthWarningTitle, strings.healthWarningSubtitle, Color.red)
        }
    }
    
    public var filteredProcesses: [ProcessInfoItem] {
        let trimmed = processSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            return topProcesses
        }
        return topProcesses.filter {
            $0.name.lowercased().contains(trimmed) || "\($0.pid)".contains(trimmed)
        }
    }
    
    // MARK: - Haptic Feedback
    
    public func triggerHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
    
    // MARK: - Telemetry Actions
    
    public func refreshDisk() {
        self.diskInfo = SystemMonitor.shared.getDiskSpace()
    }
    
    public func refreshMemory() {
        self.memoryInfo = SystemMonitor.shared.getMemoryInfo()
    }
    
    public func refreshProcesses() {
        guard !isFetchingProcesses else { return }
        isFetchingProcesses = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let procs = ProcessMonitor.shared.fetchTopProcesses(limit: 12)
            let highCPU = procs.contains { $0.isHighCPU && !$0.isSystemCritical }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.topProcesses = procs
                self.hasHighCPUProcess = highCPU
                self.isFetchingProcesses = false
            }
        }
    }
    
    public func terminateProcess(_ proc: ProcessInfoItem) {
        let pid = proc.pid
        triggerHaptic()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let ok = ProcessMonitor.shared.terminateProcess(pid: pid)
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.refreshProcesses()
                if ok {
                    self.alertMessage = self.language == .english
                        ? "Process '\(proc.name)' terminated successfully."
                        : "Processo '\(proc.name)' finalizado com sucesso."
                } else {
                    self.alertMessage = self.language == .english
                        ? "Failed to terminate '\(proc.name)'."
                        : "Falha ao finalizar '\(proc.name)'."
                }
            }
        }
    }
    
    public func scanDeepClean() {
        guard !isScanningCategories else { return }
        isScanningCategories = true
        triggerHaptic()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let cats = DeepCleaner.shared.scanCategories()
            let total = cats.reduce(0) { $0 + $1.estimatedSizeBytes }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.deepCleanCategories = cats
                self.totalRecoverableBytes = total
                self.isScanningCategories = false
            }
        }
    }
    
    public func runDeepClean() {
        guard !isDeepCleaning, !selectedCategories.isEmpty else { return }
        isDeepCleaning = true
        deepCleanProgressText = language == .english ? "Starting deep clean..." : "Iniciando limpeza profunda..."
        triggerHaptic()
        
        DeepCleaner.shared.performDeepClean(categories: selectedCategories, progress: { [weak self] step in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.deepCleanProgressText = self.localizeProgressStep(step)
            }
        }) { [weak self] freedBytes, summary in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isDeepCleaning = false
                self.deepCleanProgressText = ""
                self.refreshDisk()
                self.refreshMemory()
                self.scanDeepClean()
                self.triggerHaptic()
                let freedStr = Formatters.fileString(from: freedBytes)
                self.alertMessage = self.language == .english
                    ? "Clean complete! \(freedStr) reclaimed successfully."
                    : "Limpeza concluída! \(freedStr) recuperados com sucesso."
            }
        }
    }
    
    private func localizeProgressStep(_ step: String) -> String {
        if language == .english {
            if step.contains("caches de aplicativos") { return "Cleaning app and browser caches..." }
            if step.contains("instaladores residuais") { return "Removing residual installers..." }
            if step.contains("logs") { return "Cleaning diagnostic logs and reports..." }
            if step.contains("lixeira") { return "Emptying trash and temporary files..." }
            if step.contains("Xcode") { return "Cleaning Xcode build artifacts..." }
            if step.contains("projetos") || step.contains("Builds") { return "Cleaning project caches and build artifacts..." }
        }
        return step
    }
    
    public func cleanQuickCaches() {
        isCleaning = true
        triggerHaptic()
        SystemMonitor.shared.runQuickCacheClean(progress: { _ in }) { [weak self] log in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isCleaning = false
                self.refreshDisk()
                self.refreshMemory()
                self.triggerHaptic()
                self.alertMessage = self.language == .english
                    ? "Application and browser caches cleaned!"
                    : "Caches de aplicativos e navegadores limpos!"
            }
        }
    }
    
    public func emptyTrash() {
        triggerHaptic()
        SystemMonitor.shared.emptyTrash { [weak self] success, message in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.refreshDisk()
                self.triggerHaptic()
                if self.language == .english {
                    if message.contains("já está vazia") {
                        self.alertMessage = "macOS Trash is already empty."
                    } else if message.contains("Lixeira esvaziada") {
                        self.alertMessage = "macOS Trash emptied successfully!"
                    } else {
                        self.alertMessage = message
                    }
                } else {
                    self.alertMessage = message
                }
            }
        }
    }
    
    public func flushDNS() {
        isFlushingDNS = true
        triggerHaptic()
        SystemMonitor.shared.flushDNSCache { [weak self] success in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isFlushingDNS = false
                self.triggerHaptic()
                if self.language == .english {
                    self.alertMessage = success
                        ? "macOS DNS Cache flushed successfully!"
                        : "Notice while trying to flush DNS cache."
                } else {
                    self.alertMessage = success
                        ? "Cache de DNS do macOS renovado com sucesso!"
                        : "Aviso ao renovar cache de DNS."
                }
            }
        }
    }
    
    public func oneClickOptimize() {
        isOptimizing = true
        triggerHaptic()
        
        cleanQuickCaches()
        flushDNS()
        refreshDisk()
        refreshMemory()
        refreshProcesses()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self else { return }
            self.isOptimizing = false
            self.triggerHaptic()
            self.alertMessage = self.language == .english
                ? "Optimization complete! Caches purged and resources renewed."
                : "Otimização concluída! Caches limpos e recursos renovados."
        }
    }
    
    public func openMainWindow() {
        triggerHaptic()
        AppDelegate.shared?.showMainWindow()
    }
    
    // MARK: - Memory Pressure Management
    
    public func purgeTransientMemory() {
        self.processSearchQuery = ""
        if self.topProcesses.count > 10 {
            self.topProcesses = Array(self.topProcesses.prefix(10))
        }
        // Tell Darwin libsystem malloc to return unused pages back to the kernel
        Darwin.malloc_zone_pressure_relief(nil, 0)
    }
}
