import SwiftUI
import AppKit

public struct CleanBarView: View {
    @ObservedObject var state = AppState.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            // MARK: - Header
            headerView
            
            // MARK: - Segmented Tab Bar (Glassmorphic)
            tabBarView
            
            // MARK: - Tab Content
            switch state.selectedTab {
            case .dashboard:
                dashboardTabView
            case .deepClean:
                deepCleanTabView
            case .processes:
                processesTabView
            }
            
            // MARK: - Alert Toast
            if let msg = state.alertMessage {
                toastView(msg)
            }
        }
        .padding(14)
        .frame(width: 350)
        .background(.ultraThinMaterial)
        .alert(
            "Purgar node_modules?",
            isPresented: Binding(
                get: { state.projectToPurge != nil },
                set: { if !$0 { state.projectToPurge = nil } }
            )
        ) {
            Button("Purgar", role: .destructive) {
                if let proj = state.projectToPurge {
                    state.purgeNodeModules(for: proj)
                    state.projectToPurge = nil
                }
            }
            Button("Cancelar", role: .cancel) {
                state.projectToPurge = nil
            }
        } message: {
            if let proj = state.projectToPurge {
                Text("Deseja remover as dependências de \(proj.name) (\(proj.sizeFormatted))? Você pode reinstalar com pnpm i quando for usar.")
            }
        }
        .alert(
            "Otimizar Pasta de Vídeos?",
            isPresented: Binding(
                get: { state.showVideoConfirm },
                set: { state.showVideoConfirm = $0 }
            )
        ) {
            Button("Otimizar", role: .none) {
                state.cleanVideoCaches()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Remove pastas 'work/' temporárias e arquivos .mov pesados em ~/video, preservando masters e legendas.")
        }
        .alert(
            "Finalizar Processo?",
            isPresented: Binding(
                get: { state.processToKill != nil },
                set: { if !$0 { state.processToKill = nil } }
            )
        ) {
            Button("Encerrar Processo", role: .destructive) {
                if let proc = state.processToKill {
                    state.terminateProcess(proc)
                    state.processToKill = nil
                }
            }
            Button("Cancelar", role: .cancel) {
                state.processToKill = nil
            }
        } message: {
            if let proc = state.processToKill {
                Text("Deseja encerrar '\(proc.name)' (PID \(proc.pid)) que está usando \(String(format: "%.1f", proc.cpuPercent))% de CPU?")
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.cyan.opacity(0.8), .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 28, height: 28)
                        .blur(radius: 4)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("CleanBar")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Workspace & Deep Clean")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Button(action: {
                    state.refreshDisk()
                    state.refreshVideoStatus()
                    state.refreshProcesses()
                    if state.selectedTab == .deepClean {
                        state.scanDeepClean()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help("Atualizar status")
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help("Encerrar CleanBar")
            }
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - Tab Bar
    private var tabBarView: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                Button(action: {
                    state.selectedTab = tab
                    if tab == .deepClean && state.deepCleanCategories.isEmpty {
                        state.scanDeepClean()
                    }
                    if tab == .processes {
                        state.refreshProcesses()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 10, weight: .semibold))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .medium))
                        
                        if tab == .processes && state.hasHighCPUProcess {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        state.selectedTab == tab
                            ? Color.primary.opacity(0.12)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                    .foregroundColor(state.selectedTab == tab ? .primary : .secondary)
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
            // Storage Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Macintosh HD", systemImage: "internaldrive.fill")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(state.diskInfo.percentUsed)% usado")
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
                    }
                }
                .frame(height: 8)
                
                HStack(alignment: .firstTextBaseline) {
                    Text(state.diskInfo.freeFormatted)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    Text("livres de \(state.diskInfo.totalFormatted)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(12)
            .glassCard()
            
            // Video Pipeline Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Pipeline de Mídia", systemImage: "film.stack")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                    
                    if let folder = state.videoFolders.first {
                        Text(folder.isOptimized ? "✅ Otimizado" : "⚠️ Caches")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(folder.isOptimized ? Color.green.opacity(0.15) : Color.orange.opacity(0.15), in: Capsule())
                            .foregroundColor(folder.isOptimized ? .green : .orange)
                    }
                }
                
                HStack(spacing: 8) {
                    if let folder = state.videoFolders.first {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pasta ~/video")
                                .font(.system(size: 11, weight: .medium))
                            Text(folder.sizeFormatted)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        state.openFolder(VideoJanitor.shared.videoDirPath)
                    }) {
                        Label("Finder", systemImage: "folder")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .glassButton()
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        state.showVideoConfirm = true
                    }) {
                        Label("Purgar Caches", systemImage: "wand.and.stars")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .glassButton()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .glassCard()
            
            // Dev Workspace Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Projetos Dev", systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                    
                    if state.isScanningProjects {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 14, height: 14)
                    } else {
                        Button(action: {
                            state.scanProjects()
                        }) {
                            Text(state.devProjects.isEmpty ? "Rastrear node_modules" : "Reescanear")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.cyan)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if state.devProjects.isEmpty {
                    Text(state.isScanningProjects ? "Rastreando pastas em background..." : "Clique em 'Rastrear' para verificar dependências.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 6) {
                        ForEach(state.devProjects.prefix(3)) { proj in
                            HStack {
                                Text(proj.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(proj.sizeFormatted)
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.primary.opacity(0.08), in: Capsule())
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    state.openFolder(proj.path)
                                }) {
                                    Image(systemName: "folder")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                        .frame(width: 20, height: 20)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    state.projectToPurge = proj
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10))
                                        .foregroundColor(.red.opacity(0.8))
                                        .frame(width: 20, height: 20)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .padding(12)
            .glassCard()
            
            // Quick Actions Pills
            HStack(spacing: 8) {
                Button(action: {
                    state.cleanPackageCaches()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("Caches (pnpm/npm/brew)")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .glassButton()
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    state.emptyTrash()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .foregroundColor(.orange)
                        Text("Esvaziar Lixeira")
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
                    Text("Espaço Potencial a Liberar")
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
                    Label("Reescanear", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .glassButton()
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .glassCard()
            
            // Lista de Categorias
            VStack(spacing: 8) {
                ForEach(state.deepCleanCategories) { cat in
                    let isChecked = state.selectedCategories.contains(cat.key)
                    Button(action: {
                        if isChecked {
                            state.selectedCategories.remove(cat.key)
                        } else {
                            state.selectedCategories.insert(cat.key)
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                                .foregroundColor(isChecked ? .cyan : .secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cat.title)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(cat.subtitle)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Text(cat.sizeFormatted)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(
                            isChecked ? Color.cyan.opacity(0.08) : Color.primary.opacity(0.03),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isChecked ? Color.cyan.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .glassCard()
            
            // Botão Executar
            if state.isDeepCleaning {
                VStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(state.deepCleanProgressText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                Button(action: {
                    state.runDeepClean()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Executar Limpeza Profunda")
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
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Alta Carga de CPU!")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primary)
                        Text("\(runaway.name) está usando \(String(format: "%.1f", runaway.cpuPercent))% de CPU")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        state.processToKill = runaway
                    }) {
                        Text("Finalizar")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
            }
            
            // Lista dos Top Processos
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Consumo de CPU em Tempo Real", systemImage: "speedometer")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("Top 7")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    ForEach(state.topProcesses) { proc in
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(proc.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                                Text("PID: \(proc.pid) • RAM: \(String(format: "%.1f", proc.memPercent))%")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(String(format: "%.1f%%", proc.cpuPercent))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(proc.cpuPercent > 30 ? .red : (proc.cpuPercent > 10 ? .orange : .secondary))
                                .frame(width: 44, alignment: .trailing)
                            
                            if !proc.isSystemCritical {
                                Button(action: {
                                    state.processToKill = proc
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.red.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                                .help("Encerrar processo")
                            } else {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .help("Processo essencial do sistema")
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(
                            proc.isHighCPU ? Color.red.opacity(0.08) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                    }
                }
            }
            .padding(12)
            .glassCard()
        }
    }
    
    // MARK: - Toast Banner
    private func toastView(_ msg: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(msg)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(2)
            Spacer()
            Button(action: { state.alertMessage = nil }) {
                Image(systemName: "xmark")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 0.8))
        .transition(.opacity)
    }
}

// MARK: - Glassmorphism View Modifiers

public struct GlassCardModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.30),
                                Color.white.opacity(0.08),
                                Color.black.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

public struct GlassButtonModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
            )
    }
}

public extension View {
    func glassCard() -> some View {
        self.modifier(GlassCardModifier())
    }
    
    func glassButton() -> some View {
        self.modifier(GlassButtonModifier())
    }
}
