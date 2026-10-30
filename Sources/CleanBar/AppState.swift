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
    
    // Tab
    @Published public var selectedTab: AppTab = .dashboard
    
    // Storage & Files
    @Published public var diskInfo: DiskSpaceInfo = DiskSpaceInfo(totalBytes: 0, freeBytes: 0, usedBytes: 0)
    @Published public var largeFiles: [LargeFileItem] = []
    @Published public var folderBreakdown: [StorageFolderBreakdown] = []
    @Published public var isScanningStorage = false
    @Published public var isCleaning = false
    @Published public var alertMessage: String?
    
    // Deep Clean
    @Published public var deepCleanCategories: [CleanCategoryItem] = []
    @Published public var selectedCategories: Set<String> = ["app_caches", "installers", "system_logs", "trash_temp"]
    @Published public var isDeepCleaning = false
    @Published public var deepCleanProgressText = ""
    @Published public var totalRecoverableBytes: Int64 = 0
    
    // Process Monitor
    @Published public var topProcesses: [ProcessInfoItem] = []
    @Published public var hasHighCPUProcess = false
    
    // Modals & Actions
    @Published public var fileToTrash: LargeFileItem?
    @Published public var processToKill: ProcessInfoItem?
    
    private var diskTimer: Timer?
    private var processTimer: Timer?
    
    private init() {
        refreshDisk()
        refreshStorage()
        refreshProcesses()
        
        // Auto-refresh disk every 60s
        diskTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshDisk()
            }
        }
        
        // Auto-refresh processes every 6s
        processTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshProcesses()
            }
        }
    }
    
    public func refreshDisk() {
        self.diskInfo = SystemMonitor.shared.getDiskSpace()
    }
    
    public func refreshStorage(force: Bool = false) {
        guard !isScanningStorage else { return }
        isScanningStorage = true
        
        StorageScanner.shared.scan(force: force) { [weak self] files, breakdown in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.largeFiles = files
                self.folderBreakdown = breakdown
                self.isScanningStorage = false
            }
        }
    }
    
    public func refreshProcesses() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let procs = ProcessMonitor.shared.fetchTopProcesses(limit: 7)
            let highCPU = procs.contains { $0.isHighCPU && !$0.isSystemCritical }
            
            Task { @MainActor [weak self] in
                self?.topProcesses = procs
                self?.hasHighCPUProcess = highCPU
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
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let cats = DeepCleaner.shared.scanCategories()
            let total = cats.reduce(0) { $0 + $1.estimatedSizeBytes }
            
            Task { @MainActor [weak self] in
                self?.deepCleanCategories = cats
                self?.totalRecoverableBytes = total
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
                self.refreshStorage(force: true)
                self.scanDeepClean()
                let freedStr = ByteCountFormatter.string(fromByteCount: freedBytes, countStyle: .file)
                self.alertMessage = "Limpeza Profunda concluída! \(freedStr) recuperados."
            }
        }
    }
    
    public func trashLargeFile(_ item: LargeFileItem) {
        isCleaning = true
        let success = StorageScanner.shared.trashFile(at: item.path)
        isCleaning = false
        refreshDisk()
        refreshStorage(force: true)
        alertMessage = success ? "\(item.name) movido para a Lixeira." : "Falha ao mover arquivo."
    }
    
    public func cleanQuickCaches() {
        isCleaning = true
        SystemMonitor.shared.runQuickCacheClean(progress: { _ in }) { [weak self] log in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isCleaning = false
                self.refreshDisk()
                self.refreshStorage(force: true)
                self.alertMessage = log
            }
        }
    }
    
    public func emptyTrash() {
        SystemMonitor.shared.emptyTrash { [weak self] success in
            Task { @MainActor [weak self] in
                self?.refreshDisk()
                self?.refreshStorage(force: true)
                self?.alertMessage = success ? "Lixeira do macOS esvaziada!" : "Aviso ao tentar esvaziar lixeira."
            }
        }
    }
    
    public func openFolder(_ path: String) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
    }
    
    public func revealInFinder(_ path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: (path as NSString).deletingLastPathComponent)
    }
}
