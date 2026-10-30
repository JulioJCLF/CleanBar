import Foundation
import SwiftUI
import AppKit

public enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Visão Geral"
    case deepClean = "Limpeza Profunda"
    case processes = "Processos & CPU"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .dashboard: return "sparkles"
        case .deepClean: return "wand.and.stars"
        case .processes: return "cpu"
        }
    }
}

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    // Navigation
    @Published public var selectedTab: AppTab = .dashboard
    
    // System Vitals (Reads in < 1ms via Darwin Kernel Syscalls, Zero Disk Thrashing)
    @Published public var diskInfo: DiskSpaceInfo = DiskSpaceInfo(totalBytes: 0, freeBytes: 0, usedBytes: 0)
    @Published public var memoryInfo: MemoryInfo = MemoryInfo(totalBytes: 0, usedBytes: 0, freeBytes: 0)
    @Published public var isCleaning = false
    @Published public var alertMessage: String?
    
    // Deep Clean (Computed strictly on-demand)
    @Published public var deepCleanCategories: [CleanCategoryItem] = []
    @Published public var selectedCategories: Set<String> = ["app_caches", "installers", "system_logs", "trash_temp"]
    @Published public var isDeepCleaning = false
    @Published public var isScanningCategories = false
    @Published public var deepCleanProgressText = ""
    @Published public var totalRecoverableBytes: Int64 = 0
    
    // Process Monitor (Refreshed only when user opens tab or popover)
    @Published public var topProcesses: [ProcessInfoItem] = []
    @Published public var hasHighCPUProcess = false
    @Published public var isFetchingProcesses = false
    @Published public var processToKill: ProcessInfoItem?
    
    private var menubarTimer: Timer?
    
    private init() {
        refreshDisk()
        refreshMemory()
        
        // Refresh menubar title (POSIX statfs) every 60s
        menubarTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshDisk()
                self?.refreshMemory()
            }
        }
    }
    
    public func refreshDisk() {
        self.diskInfo = SystemMonitor.shared.getDiskSpace()
    }
    
    public func refreshMemory() {
        self.memoryInfo = SystemMonitor.shared.getMemoryInfo()
    }
    
    public func refreshProcesses() {
        guard !isFetchingProcesses else { return }
        isFetchingProcesses = true
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let procs = ProcessMonitor.shared.fetchTopProcesses(limit: 7)
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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let ok = ProcessMonitor.shared.terminateProcess(pid: pid)
            Task { @MainActor [weak self] in
                self?.refreshProcesses()
                self?.alertMessage = ok ? "Processo '\(proc.name)' finalizado com sucesso." : "Falha ao finalizar '\(proc.name)'."
            }
        }
    }
    
    public func scanDeepClean() {
        guard !isScanningCategories else { return }
        isScanningCategories = true
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
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
        deepCleanProgressText = "Iniciando limpeza profunda..."
        
        DeepCleaner.shared.performDeepClean(categories: selectedCategories, progress: { [weak self] step in
            Task { @MainActor [weak self] in
                self?.deepCleanProgressText = step
            }
        }) { [weak self] freedBytes, summary in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isDeepCleaning = false
                self.deepCleanProgressText = ""
                self.refreshDisk()
                self.refreshMemory()
                self.scanDeepClean()
                let freedStr = ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file)
                self.alertMessage = "Limpeza concluída! \(freedStr) recuperados."
            }
        }
    }
    
    public func cleanQuickCaches() {
        isCleaning = true
        SystemMonitor.shared.runQuickCacheClean(progress: { _ in }) { [weak self] log in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isCleaning = false
                self.refreshDisk()
                self.refreshMemory()
                self.alertMessage = log
            }
        }
    }
    
    public func emptyTrash() {
        SystemMonitor.shared.emptyTrash { [weak self] success in
            Task { @MainActor [weak self] in
                self?.refreshDisk()
                self?.alertMessage = success ? "Lixeira do macOS esvaziada!" : "Aviso ao tentar esvaziar lixeira."
            }
        }
    }
}
