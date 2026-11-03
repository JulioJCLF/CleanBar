import SwiftUI
import AppKit

public struct CleanBarView: View {
    @ObservedObject var state = AppState.shared
    @Namespace private var popoverTabNamespace
    
    public init() {}
    
    // Core tabs visible in the compact popover
    private var popoverTabs: [AppTab] {
        [.dashboard, .deepClean, .processes]
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // MARK: - Header
            headerView
            
            // MARK: - Segmented Tab Bar (Glassmorphic Animated)
            tabBarView
            
            // MARK: - Tab Content with Transition
            ZStack {
                switch state.selectedTab {
                case .dashboard, .quickTools, .settings:
                    dashboardTabView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        ))
                case .deepClean:
                    deepCleanTabView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        ))
                case .processes:
                    processesTabView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        ))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: state.selectedTab)
            
            // MARK: - Open Full App Window Footer
            Button(action: {
                state.triggerHaptic()
                AppDelegate.shared?.closePopover()
                MainWindowController.shared.showWindow()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "macwindow")
                        .font(.system(size: 11, weight: .semibold))
                    Text(state.strings.openAppWindow)
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.cyan.opacity(0.25), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
            .hoverLift(elevation: 1, scale: 1.005)
            
            // MARK: - Alert Toast
            if let msg = state.alertMessage {
                toastView(msg)
            }
        }
        .padding(14)
        .frame(width: 350)
        .background(.ultraThinMaterial)
        .alert(
            state.strings.killProcessTitle,
            isPresented: Binding(
                get: { state.processToKill != nil },
                set: { if !$0 { state.processToKill = nil } }
            )
        ) {
            Button(state.strings.terminateButton, role: .destructive) {
                if let proc = state.processToKill {
                    state.terminateProcess(proc)
                    state.processToKill = nil
                }
            }
            Button(state.strings.cancel, role: .cancel) {
                state.processToKill = nil
            }
        } message: {
            if let proc = state.processToKill {
                Text(state.strings.killProcessMessage(name: proc.name, pid: proc.pid, cpu: proc.cpuPercent))
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.cyan.opacity(0.9), .purple.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                        .blur(radius: 2)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("CleanBar")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("macOS Janitor")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                // Language Quick Switcher
                Button(action: {
                    state.triggerHaptic()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        state.language = (state.language == .english) ? .portuguese : .english
                    }
                }) {
                    Text(state.language == .english ? "🇺🇸" : "🇧🇷")
                        .font(.system(size: 11))
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help("Language / Idioma")
                
                // Open Standalone Window Button
                Button(action: {
                    state.triggerHaptic()
                    AppDelegate.shared?.closePopover()
                    MainWindowController.shared.showWindow()
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.cyan)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.cyan.opacity(0.35), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help(state.strings.openAppWindow)
                
                // Refresh Button
                Button(action: {
                    state.triggerHaptic()
                    state.refreshDisk()
                    state.refreshMemory()
                    if state.selectedTab == .processes {
                        state.refreshProcesses()
                    }
                    if state.selectedTab == .deepClean {
                        state.scanDeepClean()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help(state.strings.refresh)
                
                // Close Popover
                Button(action: {
                    AppDelegate.shared?.closePopover()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help(state.strings.closePopoverTooltip)
                
                // Quit App
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help(state.strings.quitApp)
            }
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - Tab Bar
    private var tabBarView: some View {
        HStack(spacing: 4) {
            ForEach(popoverTabs) { tab in
                let isSelected = state.selectedTab == tab
                Button(action: {
                    state.triggerHaptic()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        state.selectedTab = tab
                    }
                    if tab == .deepClean && state.deepCleanCategories.isEmpty {
                        state.scanDeepClean()
                    }
                    if tab == .processes && state.topProcesses.isEmpty {
                        state.refreshProcesses()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 10, weight: .semibold))
                        
                        Text(state.strings.tabTitle(tab))
                            .font(.system(size: 11, weight: .medium))
                        
                        if tab == .processes && state.hasHighCPUProcess {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                                .pulsingGlow()
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.primary.opacity(0.12))
                                    .matchedGeometryEffect(id: "popoverTabIndicator", in: popoverTabNamespace)
                            }
                        }
                    )
                    .foregroundColor(isSelected ? .primary : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
        )
    }
    
    // MARK: - Tab 1: Dashboard
    private var dashboardTabView: some View {
        VStack(spacing: 12) {
            // Storage Gauge Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(state.strings.macintoshHD, systemImage: "internaldrive.fill")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: state.strings.percentUsed, state.diskInfo.percentUsed))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color.mint, Color.cyan, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: max(8, geo.size.width * CGFloat(state.diskInfo.percentUsed) / 100.0), height: 8)
                            .shadow(color: Color.cyan.opacity(0.5), radius: 4, x: 0, y: 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: state.diskInfo.percentUsed)
                    }
                }
                .frame(height: 8)
                
                HStack(alignment: .firstTextBaseline) {
                    Text(state.diskInfo.freeFormatted)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    Text(String(format: state.strings.freeOfTotal, state.diskInfo.totalFormatted))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(12)
            .glassCard()
            .hoverLift(elevation: 1.5, scale: 1.005)
            
            // Memory RAM Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(state.strings.ramMemory, systemImage: "memorychip.fill")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: state.strings.percentOccupied, state.memoryInfo.percentUsed))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color.purple, Color.indigo, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: max(8, geo.size.width * CGFloat(state.memoryInfo.percentUsed) / 100.0), height: 8)
                            .shadow(color: Color.purple.opacity(0.4), radius: 4, x: 0, y: 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: state.memoryInfo.percentUsed)
                    }
                }
                .frame(height: 8)
                
                HStack(alignment: .firstTextBaseline) {
                    Text(state.memoryInfo.freeFormatted)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    Text(String(format: state.strings.availableOfTotal, state.memoryInfo.totalFormatted))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(12)
            .glassCard()
            .hoverLift(elevation: 1.5, scale: 1.005)
            
            // Deep Clean Callout Card
            Button(action: {
                state.triggerHaptic()
                state.selectedTab = .deepClean
                state.scanDeepClean()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16))
                        .foregroundColor(.cyan)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.strings.tabTitle(.deepClean))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(state.language == .english ? "Caches, residual installers and logs" : "Caches, instaladores residuais e logs")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .glassCard()
            }
            .buttonStyle(.plain)
            .hoverLift(elevation: 1.5, scale: 1.005)
            
            // Quick Actions Pills
            HStack(spacing: 8) {
                Button(action: {
                    state.cleanQuickCaches()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text(state.isCleaning ? state.strings.toolQuickCacheCleaning : state.strings.toolQuickCacheButton)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .glassButton()
                }
                .buttonStyle(.plain)
                .disabled(state.isCleaning)
                
                Button(action: {
                    state.emptyTrash()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .foregroundColor(.orange)
                        Text(state.strings.toolEmptyTrashButton)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .glassButton()
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Tab 2: Limpeza Profunda
    private var deepCleanTabView: some View {
        VStack(spacing: 10) {
            // Banner total recuperável
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.strings.potentialSpaceToReclaim)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(ByteCountFormatter.string(fromByteCount: state.totalRecoverableBytes, countStyle: .file))
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.cyan)
                }
                Spacer()
                Button(action: {
                    state.scanDeepClean()
                }) {
                    Label(state.isScanningCategories ? state.strings.scanning : state.strings.rescan, systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .glassButton()
                }
                .buttonStyle(.plain)
                .disabled(state.isScanningCategories)
            }
            .padding(12)
            .glassCard()
            
            // Lista de Categorias
            VStack(spacing: 6) {
                ForEach(state.deepCleanCategories) { cat in
                    let isChecked = state.selectedCategories.contains(cat.key)
                    Button(action: {
                        state.triggerHaptic()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            if isChecked {
                                state.selectedCategories.remove(cat.key)
                            } else {
                                state.selectedCategories.insert(cat.key)
                            }
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                                .foregroundColor(isChecked ? .cyan : .secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(state.strings.categoryTitle(for: cat.key))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(state.strings.categorySubtitle(for: cat.key))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Text(cat.sizeFormatted)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(
                            isChecked ? Color.cyan.opacity(0.08) : Color.primary.opacity(0.03),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isChecked ? Color.cyan.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .glassCard()
            
            // Botão Executar
            if state.isDeepCleaning {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(.cyan)
                            .continuousSpin()
                        Text(state.deepCleanProgressText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    ProgressView()
                        .scaleEffect(0.7)
                }
                .padding(.vertical, 8)
            } else {
                Button(action: {
                    state.runDeepClean()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(state.strings.runDeepClean)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .foregroundColor(.white)
                    .shadow(color: Color.cyan.opacity(0.4), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(state.selectedCategories.isEmpty)
                .opacity(state.selectedCategories.isEmpty ? 0.5 : 1.0)
            }
        }
    }
    
    // MARK: - Tab 3: Processos & CPU Tamer
    private var processesTabView: some View {
        VStack(spacing: 10) {
            // Alerta se houver CPU alta
            if let runaway = state.topProcesses.first(where: { $0.isHighCPU && !$0.isSystemCritical }) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                        .pulsingGlow()
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(state.strings.highCPULoadAlert)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primary)
                        Text(state.strings.highCPUSubtitle(name: runaway.name, percent: runaway.cpuPercent))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        state.processToKill = runaway
                    }) {
                        Text(state.strings.endNow)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.red.opacity(0.4), lineWidth: 0.8))
            }
            
            // Lista dos Maiores Processos
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(state.language == .english ? "Real-time CPU Load" : "Consumo de CPU em Tempo Real", systemImage: "waveform.path.ecg")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                    
                    if state.isFetchingProcesses {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 14, height: 14)
                    } else {
                        Button(action: {
                            state.refreshProcesses()
                        }) {
                            Text(state.strings.refresh)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.cyan)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if state.topProcesses.isEmpty {
                    Text(state.strings.noProcessesFound)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 6)
                } else {
                    VStack(spacing: 4) {
                        ForEach(state.topProcesses) { proc in
                            HStack(spacing: 8) {
                                Text(proc.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(proc.isSystemCritical ? .secondary : .primary)
                                    .lineLimit(1)
                                
                                if proc.isSystemCritical {
                                    Text("macOS")
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.primary.opacity(0.06), in: Capsule())
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // CPU Bar
                                GeometryReader { barGeo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.primary.opacity(0.06))
                                            .frame(height: 5)
                                        
                                        Capsule()
                                            .fill(proc.isHighCPU ? Color.red : Color.cyan)
                                            .frame(width: max(3, barGeo.size.width * CGFloat(min(proc.cpuPercent, 100.0)) / 100.0), height: 5)
                                    }
                                }
                                .frame(width: 50, height: 5)
                                
                                Text(String(format: "%4.1f%%", proc.cpuPercent))
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(proc.isHighCPU ? .red : .secondary)
                                    .frame(width: 42, alignment: .trailing)
                                
                                if !proc.isSystemCritical {
                                    Button(action: {
                                        state.processToKill = proc
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red.opacity(0.7))
                                    }
                                    .buttonStyle(.plain)
                                    .help(state.language == .english ? "Terminate process" : "Finalizar processo")
                                } else {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary.opacity(0.4))
                                        .frame(width: 12)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
            .padding(12)
            .glassCard()
        }
    }
    
    // MARK: - Toast View
    private func toastView(_ msg: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 12))
            Text(msg)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 0.8))
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - View Modifiers
extension View {
    public func glassCard() -> some View {
        self
            .background(
                Color.primary.opacity(0.04),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
            )
    }
    
    public func glassButton() -> some View {
        self
            .background(
                Color.primary.opacity(0.07),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
            )
    }
}
