import SwiftUI
import AppKit

public struct CleanBarMainWindowView: View {
    @ObservedObject var state = AppState.shared
    @ObservedObject var permissions = PermissionsManager.shared
    @Namespace private var navNamespace
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Sidebar Navigation
            sidebarView
                .frame(width: 230)
                .background(.ultraThinMaterial)
            
            Divider()
                .opacity(0.3)
            
            // MARK: - Main Content Detail Area
            VStack(spacing: 0) {
                // Top Window Header / Toolbar
                windowHeaderView
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.primary.opacity(0.02))
                
                Divider()
                    .opacity(0.2)
                
                // Tab Content View
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 20) {
                        switch state.selectedTab {
                        case .dashboard:
                            dashboardView
                        case .deepClean:
                            deepCleanView
                        case .processes:
                            processesView
                        case .quickTools:
                            quickToolsView
                        case .settings:
                            settingsView
                        }
                    }
                    .padding(24)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: state.selectedTab)
                }
                
                // Bottom Alert Toast if active
                if let msg = state.alertMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        Text(msg)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: { state.alertMessage = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .overlay(
                        Rectangle().frame(height: 1).foregroundColor(Color.cyan.opacity(0.3)),
                        alignment: .top
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial)
        }
        .frame(minWidth: 820, minHeight: 560)
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
    
    // MARK: - Sidebar View
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // App Branding
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.cyan.opacity(0.5), radius: 8, x: 0, y: 2)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("CleanBar")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("v1.1.0")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.08), in: Capsule())
                            .foregroundColor(.secondary)
                    }
                    Text("macOS System Janitor")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 8)
            
            // Navigation Links
            VStack(spacing: 4) {
                ForEach(AppTab.allCases) { tab in
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
                        HStack(spacing: 10) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 20)
                                .foregroundColor(isSelected ? .cyan : .secondary)
                            
                            Text(state.strings.tabTitle(tab))
                                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                                .foregroundColor(isSelected ? .primary : .secondary)
                            
                            Spacer()
                            
                            // Badge notifications
                            if tab == .processes && state.hasHighCPUProcess {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .pulsingGlow(color: .red)
                            }
                            if tab == .deepClean && state.totalRecoverableBytes > 0 {
                                Text(Formatters.fileString(from: state.totalRecoverableBytes))
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.cyan.opacity(0.15), in: Capsule())
                                    .foregroundColor(.cyan)
                            }
                        }
                        .padding(.vertical, 9)
                        .padding(.horizontal, 12)
                        .background(
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.cyan.opacity(0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                        )
                                        .matchedGeometryEffect(id: "sidebarSelection", in: navNamespace)
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            
            Spacer()
            
            // Health Score Mini Card in Sidebar Footer
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    GaugeRingView(
                        percentage: state.macHealthScore,
                        lineWidth: 4,
                        gradient: LinearGradient(colors: [state.macHealthStatus.color, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                        labelFont: .system(size: 11, weight: .bold, design: .rounded)
                    )
                    .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(state.strings.macHealth)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                        Text(state.macHealthStatus.title)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(state.macHealthStatus.color)
                    }
                }
                
                Button(action: {
                    state.oneClickOptimize()
                }) {
                    HStack(spacing: 6) {
                        if state.isOptimizing {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow)
                        }
                        Text(state.isOptimizing ? state.strings.optimizing : state.strings.quickOptimize)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .polishedGlassButton()
                }
                .buttonStyle(.plain)
                .disabled(state.isOptimizing)
            }
            .padding(12)
            .polishedGlassCard(cornerRadius: 12)
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Window Header View
    private var windowHeaderView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(state.strings.tabTitle(state.selectedTab))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(state.strings.headerSubtitle(for: state.selectedTab))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                // Quick Language Toggle
                Button(action: {
                    state.triggerHaptic()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        state.language = (state.language == .english) ? .portuguese : .english
                    }
                }) {
                    Text(state.language == .english ? "🇺🇸 EN" : "🇧🇷 PT")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .polishedGlassButton()
                }
                .buttonStyle(.plain)
                .help("Mudar Idioma / Switch Language")
                
                // Refresh Button with Spin Animation
                Button(action: {
                    state.triggerHaptic()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        state.isRefreshing = true
                    }
                    state.refreshDisk()
                    state.refreshMemory()
                    if state.selectedTab == .processes {
                        state.refreshProcesses()
                    }
                    if state.selectedTab == .deepClean {
                        state.scanDeepClean()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        state.isRefreshing = false
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .rotationEffect(.degrees(state.isRefreshing ? 360 : 0))
                        Text(state.strings.refresh)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .polishedGlassButton()
                }
                .buttonStyle(.plain)
                .help(state.strings.refreshTooltip)
            }
        }
    }
    
    // MARK: - 1. Dashboard View
    private var dashboardView: some View {
        VStack(spacing: 18) {
            // Hero Health Status Card
            HStack(spacing: 24) {
                GaugeRingView(
                    percentage: state.macHealthScore,
                    lineWidth: 10,
                    gradient: LinearGradient(colors: [state.macHealthStatus.color, .cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                    labelFont: .system(size: 26, weight: .heavy, design: .rounded)
                )
                .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(state.strings.generalStatus)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(state.macHealthStatus.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(state.macHealthStatus.color)
                    }
                    
                    Text(state.macHealthStatus.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Circle().fill(state.diskInfo.percentUsed > 85 ? Color.orange : Color.green).frame(width: 7, height: 7)
                            Text(String(format: state.strings.diskFreeSummary, 100 - state.diskInfo.percentUsed))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 4) {
                            Circle().fill(state.memoryInfo.percentUsed > 85 ? Color.orange : Color.green).frame(width: 7, height: 7)
                            Text(String(format: state.strings.ramUsedSummary, state.memoryInfo.percentUsed))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        if state.hasHighCPUProcess {
                            HStack(spacing: 4) {
                                Circle().fill(Color.red).frame(width: 7, height: 7).pulsingGlow()
                                Text(state.strings.cpuAlertSummary)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
                
                Button(action: {
                    state.oneClickOptimize()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .bold))
                        Text(state.isOptimizing ? state.strings.optimizing : state.strings.optimizeMac)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .shadow(color: Color.cyan.opacity(0.4), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(state.isOptimizing)
            }
            .padding(20)
            .polishedGlassCard(cornerRadius: 16)
            .hoverLift(elevation: 2, scale: 1.005)
            
            // Storage & RAM Grid
            HStack(spacing: 16) {
                // Storage Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label(state.strings.macintoshHD, systemImage: "internaldrive.fill")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(String(format: state.strings.percentUsed, state.diskInfo.percentUsed))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.08))
                                .frame(height: 10)
                            
                            Capsule()
                                .fill(LinearGradient(colors: [.mint, .cyan, .blue], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(10, geo.size.width * CGFloat(state.diskInfo.percentUsed) / 100.0), height: 10)
                                .shadow(color: Color.cyan.opacity(0.4), radius: 4, x: 0, y: 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: state.diskInfo.percentUsed)
                        }
                    }
                    .frame(height: 10)
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text(state.diskInfo.freeFormatted)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary)
                        Text(String(format: state.strings.freeOfTotal, state.diskInfo.totalFormatted))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        state.selectedTab = .deepClean
                        state.scanDeepClean()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "wand.and.stars")
                            Text(state.strings.examineDeepClean)
                                .font(.system(size: 11, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .polishedGlassButton()
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .polishedGlassCard(cornerRadius: 14)
                .hoverLift(elevation: 2, scale: 1.005)
                
                // RAM Memory Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label(state.strings.ramMemory, systemImage: "memorychip.fill")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(String(format: state.strings.percentOccupied, state.memoryInfo.percentUsed))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.08))
                                .frame(height: 10)
                            
                            Capsule()
                                .fill(LinearGradient(colors: [.purple, .indigo, .blue], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(10, geo.size.width * CGFloat(state.memoryInfo.percentUsed) / 100.0), height: 10)
                                .shadow(color: Color.purple.opacity(0.4), radius: 4, x: 0, y: 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: state.memoryInfo.percentUsed)
                        }
                    }
                    .frame(height: 10)
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text(state.memoryInfo.freeFormatted)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary)
                        Text(String(format: state.strings.availableOfTotal, state.memoryInfo.totalFormatted))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Text("\(state.strings.activeRam): \(state.memoryInfo.activeFormatted)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("•")
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("\(state.strings.wiredRam): \(state.memoryInfo.wiredFormatted)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, 2)
                }
                .padding(16)
                .polishedGlassCard(cornerRadius: 14)
                .hoverLift(elevation: 2, scale: 1.005)
            }
            
            // System Telemetry Cards Grid
            HStack(spacing: 12) {
                telemetryPill(title: state.strings.uptime, value: SystemMonitor.shared.systemUptimeFormatted, icon: "clock.arrow.circlepath", color: .cyan)
                telemetryPill(title: state.strings.processor, value: SystemMonitor.shared.processorFormatted, icon: "cpu", color: .purple)
                telemetryPill(title: state.strings.osVersion, value: SystemMonitor.shared.osVersionFormatted, icon: "apple.logo", color: .blue)
                telemetryPill(title: state.strings.processesTitle, value: String(format: state.strings.processesCount, state.topProcesses.count), icon: "waveform.path.ecg", color: .green)
            }
        }
    }
    
    private func telemetryPill(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(12)
        .polishedGlassCard(cornerRadius: 10)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 2. Deep Clean View
    private var deepCleanView: some View {
        VStack(spacing: 18) {
            // One-Time Permission Guidance Banner (Shown if Full Disk Access is not active)
            if !permissions.hasFullDiskAccess {
                HStack(spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.cyan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.strings.permissionBannerTitle)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                        Text(state.strings.permissionBannerSubtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        state.triggerHaptic()
                        permissions.openFullDiskAccessSettings()
                    }) {
                        Text(state.strings.openSettingsButton)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .polishedGlassButton(isHighlighted: true)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 0.8)
                )
            }
            
            // Reclaimable Hero Banner
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(state.strings.potentialSpaceToReclaim)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(Formatters.fileString(from: state.totalRecoverableBytes))
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.cyan)
                    
                    Text(state.strings.deepCleanSubtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button(action: {
                        state.scanDeepClean()
                    }) {
                        HStack(spacing: 6) {
                            if state.isScanningCategories {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 14, height: 14)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text(state.isScanningCategories ? state.strings.scanning : state.strings.rescan)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .polishedGlassButton()
                    }
                    .buttonStyle(.plain)
                    .disabled(state.isScanningCategories)
                    
                    HStack(spacing: 8) {
                        Button(state.strings.selectAll) {
                            state.selectedCategories = Set(state.deepCleanCategories.map { $0.key })
                        }
                        .font(.system(size: 10, weight: .medium))
                        .buttonStyle(.plain)
                        .foregroundColor(.cyan)
                        
                        Text("•").foregroundColor(.secondary.opacity(0.4))
                        
                        Button(state.strings.deselect) {
                            state.selectedCategories.removeAll()
                        }
                        .font(.system(size: 10, weight: .medium))
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .polishedGlassCard(cornerRadius: 16)
            
            // Categories List
            VStack(spacing: 10) {
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
                        HStack(spacing: 14) {
                            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundColor(isChecked ? .cyan : .secondary)
                                .scaleEffect(isChecked ? 1.05 : 1.0)
                            
                            Image(systemName: cat.icon)
                                .font(.system(size: 15))
                                .foregroundColor(.cyan)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(state.strings.categoryTitle(for: cat.key))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(state.strings.categorySubtitle(for: cat.key))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(cat.sizeFormatted)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(isChecked ? .primary : .secondary)
                                .monospacedDigit()
                        }
                        .padding(14)
                        .background(
                            isChecked ? Color.cyan.opacity(0.08) : Color.primary.opacity(0.02),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isChecked ? Color.cyan.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .hoverLift(elevation: 2, scale: 1.004)
                }
            }
            
            // Action Clean Button
            if state.isDeepCleaning {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(.cyan)
                            .continuousSpin(duration: 1.5)
                        
                        Text(state.deepCleanProgressText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    ProgressView()
                        .scaleEffect(0.8)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .polishedGlassCard(cornerRadius: 12)
            } else {
                Button(action: {
                    state.runDeepClean()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                        Text(state.strings.runDeepClean)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .foregroundColor(.white)
                    .shadow(color: Color.cyan.opacity(0.4), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(state.selectedCategories.isEmpty)
                .opacity(state.selectedCategories.isEmpty ? 0.5 : 1.0)
            }
        }
    }
    
    // MARK: - 3. Processes & CPU View
    private var processesView: some View {
        VStack(spacing: 16) {
            // Runaway Process Alert Banner
            if let runaway = state.topProcesses.first(where: { $0.isHighCPU && !$0.isSystemCritical }) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                        .pulsingGlow(color: .red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.strings.highCPULoadAlert)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                        Text(state.strings.highCPUSubtitle(name: runaway.name, percent: runaway.cpuPercent))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        state.processToKill = runaway
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.octagon.fill")
                            Text(state.strings.endNow)
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.red, in: Capsule())
                        .shadow(color: Color.red.opacity(0.4), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.red.opacity(0.4), lineWidth: 1))
            }
            
            // Search Filter and Refresh Bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    TextField(state.strings.filterPlaceholder, text: $state.processSearchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                    
                    if !state.processSearchQuery.isEmpty {
                        Button(action: { state.processSearchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .polishedGlassButton()
                
                Spacer()
                
                Button(action: {
                    state.refreshProcesses()
                }) {
                    HStack(spacing: 6) {
                        if state.isFetchingProcesses {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(state.strings.refreshList)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .polishedGlassButton()
                }
                .buttonStyle(.plain)
                .disabled(state.isFetchingProcesses)
            }
            
            // Process Table
            VStack(spacing: 1) {
                // Header row
                HStack(spacing: 12) {
                    Text(state.strings.colProcess)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(state.strings.colPID)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .trailing)
                    
                    Text(state.strings.colCPU)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 130, alignment: .trailing)
                    
                    Text(state.strings.colActions)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.04))
                
                Divider().opacity(0.2)
                
                if state.filteredProcesses.isEmpty {
                    Text(state.isFetchingProcesses ? state.strings.readingProcesses : state.strings.noProcessesFound)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(24)
                } else {
                    ForEach(state.filteredProcesses) { proc in
                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Text(proc.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(proc.isSystemCritical ? .secondary : .primary)
                                    .lineLimit(1)
                                
                                if proc.isSystemCritical {
                                    Text("macOS")
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.primary.opacity(0.08), in: Capsule())
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("\(proc.pid)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .trailing)
                            
                            // CPU Bar + Percentage
                            HStack(spacing: 8) {
                                GeometryReader { barGeo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.primary.opacity(0.08))
                                            .frame(height: 6)
                                        
                                        Capsule()
                                            .fill(proc.isHighCPU ? Color.red : Color.cyan)
                                            .frame(width: max(4, barGeo.size.width * CGFloat(min(proc.cpuPercent, 100.0)) / 100.0), height: 6)
                                    }
                                }
                                .frame(width: 70, height: 6)
                                
                                Text(String(format: "%4.1f%%", proc.cpuPercent))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(proc.isHighCPU ? .red : .primary)
                                    .frame(width: 48, alignment: .trailing)
                            }
                            .frame(width: 130, alignment: .trailing)
                            
                            // Action
                            HStack {
                                if !proc.isSystemCritical {
                                    Button(action: {
                                        state.processToKill = proc
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.red.opacity(0.8))
                                    }
                                    .buttonStyle(.plain)
                                    .help(state.language == .english ? "Terminate process" : "Finalizar processo")
                                } else {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary.opacity(0.4))
                                }
                            }
                            .frame(width: 60, alignment: .trailing)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        
                        Divider().opacity(0.1)
                    }
                }
            }
            .polishedGlassCard(cornerRadius: 12)
        }
    }
    
    // MARK: - 4. Quick Tools View
    private var quickToolsView: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                quickToolCard(
                    title: state.strings.toolQuickCacheTitle,
                    subtitle: state.strings.toolQuickCacheSubtitle,
                    icon: "bolt.fill",
                    color: .yellow,
                    buttonLabel: state.isCleaning ? state.strings.toolQuickCacheCleaning : state.strings.toolQuickCacheButton,
                    isLoading: state.isCleaning
                ) {
                    state.cleanQuickCaches()
                }
                
                quickToolCard(
                    title: state.strings.toolEmptyTrashTitle,
                    subtitle: state.strings.toolEmptyTrashSubtitle,
                    icon: "trash.fill",
                    color: .orange,
                    buttonLabel: state.strings.toolEmptyTrashButton,
                    isLoading: false
                ) {
                    state.emptyTrash()
                }
                
                quickToolCard(
                    title: state.strings.toolFlushDNSTitle,
                    subtitle: state.strings.toolFlushDNSSubtitle,
                    icon: "network",
                    color: .cyan,
                    buttonLabel: state.isFlushingDNS ? state.strings.toolFlushDNSFlushing : state.strings.toolFlushDNSButton,
                    isLoading: state.isFlushingDNS
                ) {
                    state.flushDNS()
                }
                
                quickToolCard(
                    title: state.strings.toolFullOptimizeTitle,
                    subtitle: state.strings.toolFullOptimizeSubtitle,
                    icon: "sparkles",
                    color: .purple,
                    buttonLabel: state.isOptimizing ? state.strings.optimizing : state.strings.toolFullOptimizeButton,
                    isLoading: state.isOptimizing
                ) {
                    state.oneClickOptimize()
                }
            }
        }
    }
    
    private func quickToolCard(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        buttonLabel: String,
        isLoading: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(maxHeight: .infinity, alignment: .topLeading)
            
            Button(action: action) {
                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 14, height: 14)
                    }
                    Text(buttonLabel)
                        .font(.system(size: 12, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .polishedGlassButton(isHighlighted: true)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(16)
        .polishedGlassCard(cornerRadius: 14)
        .hoverLift(elevation: 2, scale: 1.006)
    }
    
    // MARK: - 5. Settings View
    private var settingsView: some View {
        VStack(spacing: 18) {
            // Language Picker Card
            VStack(alignment: .leading, spacing: 12) {
                Text(state.strings.languageSection)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { lang in
                        let isSelected = state.language == lang
                        Button(action: {
                            state.triggerHaptic()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                state.language = lang
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isSelected ? .cyan : .secondary)
                                Text(lang.displayName)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .primary : .secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                isSelected ? Color.cyan.opacity(0.12) : Color.primary.opacity(0.04),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(isSelected ? Color.cyan.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(18)
            .polishedGlassCard(cornerRadius: 14)
            
            // General Preferences Card
            VStack(alignment: .leading, spacing: 14) {
                Text(state.strings.displayPreferences)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                Toggle(isOn: $state.keepInDock) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.strings.keepInDockTitle)
                            .font(.system(size: 12, weight: .medium))
                        Text(state.strings.keepInDockSubtitle)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
                
                Divider().opacity(0.2)
                
                Toggle(isOn: $state.showDiskInMenubar) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(state.strings.showMenubarTitle)
                            .font(.system(size: 12, weight: .medium))
                        Text(state.strings.showMenubarSubtitle)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
            }
            .padding(18)
            .polishedGlassCard(cornerRadius: 14)
            
            // Permissions & Privacy Card
            VStack(alignment: .leading, spacing: 14) {
                Text(state.strings.permissionsSection)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(state.strings.permissionsDescription)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                // Full Disk Access (1-Click Permanent Solution)
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 20))
                        .foregroundColor(permissions.hasFullDiskAccess ? .green : .cyan)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(state.strings.fullDiskAccessTitle)
                                .font(.system(size: 12, weight: .semibold))
                            if permissions.hasFullDiskAccess {
                                Text(state.strings.grantedBadge)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15), in: Capsule())
                                    .foregroundColor(.green)
                            }
                        }
                        Text(state.strings.fullDiskAccessSubtitle)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        state.triggerHaptic()
                        permissions.openFullDiskAccessSettings()
                    }) {
                        Text(state.strings.openSettingsButton)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .polishedGlassButton(isHighlighted: true)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                // Downloads Access
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(permissions.hasDownloadsAccess ? .green : .orange)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(state.strings.downloadsAccessTitle)
                                .font(.system(size: 12, weight: .semibold))
                            if permissions.hasDownloadsAccess {
                                Text(state.strings.grantedBadge)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.15), in: Capsule())
                                    .foregroundColor(.green)
                            }
                        }
                        Text(state.strings.downloadsAccessSubtitle)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !permissions.hasDownloadsAccess {
                        Button(action: {
                            state.triggerHaptic()
                            permissions.requestDownloadsAccess()
                        }) {
                            Text(state.strings.grantButton)
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .polishedGlassButton(isHighlighted: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(18)
            .polishedGlassCard(cornerRadius: 14)
            
            // Login Item Instructions Card
            VStack(alignment: .leading, spacing: 10) {
                Text(state.strings.startWithMacTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(state.strings.startWithMacSubtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(state.strings.step1)
                    Text(state.strings.step2)
                    Text(state.strings.step3)
                }
                .font(.system(size: 11))
                .foregroundColor(.primary)
                .padding(12)
                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(18)
            .polishedGlassCard(cornerRadius: 14)
            
            // About Card
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("CleanBar v1.1.0")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text(state.strings.nativeBadge)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(state.strings.mitLicense)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    if let url = URL(string: "https://github.com/JulioJCLF/CleanBar") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                        Text(state.strings.githubRepo)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .polishedGlassButton()
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .polishedGlassCard(cornerRadius: 14)
        }
    }
}
