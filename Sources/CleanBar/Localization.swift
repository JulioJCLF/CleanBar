import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case portuguese = "pt"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .english: return "English 🇺🇸"
        case .portuguese: return "Português 🇧🇷"
        }
    }
}

public struct Strings {
    public let lang: AppLanguage
    
    public init(lang: AppLanguage) {
        self.lang = lang
    }
    
    // MARK: - Navigation Tabs
    public func tabTitle(_ tab: AppTab) -> String {
        switch tab {
        case .dashboard: return lang == .english ? "Overview" : "Visão Geral"
        case .deepClean: return lang == .english ? "Deep Clean" : "Limpeza Profunda"
        case .processes: return lang == .english ? "Processes & CPU" : "Processos & CPU"
        case .quickTools: return lang == .english ? "Maintenance" : "Manutenção"
        case .settings: return lang == .english ? "Settings" : "Configurações"
        }
    }
    
    public func headerSubtitle(for tab: AppTab) -> String {
        switch tab {
        case .dashboard:
            return lang == .english
                ? "Instant monitoring of disk, memory and macOS vitals"
                : "Monitoramento instantâneo de disco, memória e vitalidade do macOS"
        case .deepClean:
            return lang == .english
                ? "Deep recovery of free SSD storage with zero risk"
                : "Recuperação profunda de espaço livre em disco sem riscos"
        case .processes:
            return lang == .english
                ? "Process sentinel and CPU runaway loop neutralizer"
                : "Sentinela de processos e neutralizador de travamentos de CPU"
        case .quickTools:
            return lang == .english
                ? "One-click maintenance actions to speed up your system"
                : "Ações de manutenção em um clique para acelerar o sistema"
        case .settings:
            return lang == .english
                ? "App preferences, language options and startup configuration"
                : "Personalização de idioma, preferências de janela e inicialização"
        }
    }
    
    // MARK: - Common Actions
    public var refresh: String { lang == .english ? "Refresh" : "Atualizar" }
    public var refreshTooltip: String { lang == .english ? "Refresh all system metrics (Cmd+R)" : "Atualizar todas as métricas do sistema (Cmd+R)" }
    public var openAppWindow: String { lang == .english ? "Open Application Window" : "Abrir Janela do Aplicativo" }
    public var closePopoverTooltip: String { lang == .english ? "Close panel (ESC)" : "Fechar painel (ESC)" }
    public var quitApp: String { lang == .english ? "Quit CleanBar" : "Sair do CleanBar" }
    public var cancel: String { lang == .english ? "Cancel" : "Cancelar" }
    public var updating: String { lang == .english ? "Updating..." : "Atualizando..." }
    
    // MARK: - Dashboard
    public var macHealth: String { lang == .english ? "Mac Health" : "Saúde do Mac" }
    public var generalStatus: String { lang == .english ? "General Status:" : "Status Geral:" }
    public var healthExcellentTitle: String { lang == .english ? "Excellent" : "Excelente" }
    public var healthExcellentSubtitle: String { lang == .english ? "Your Mac is running fast with abundant resources." : "Seu Mac está veloz e com recursos abundantes." }
    public var healthGoodTitle: String { lang == .english ? "Good" : "Bom" }
    public var healthGoodSubtitle: String { lang == .english ? "Stable operation with cleaning opportunities." : "Operação estável, com oportunidades de limpeza." }
    public var healthWarningTitle: String { lang == .english ? "Attention" : "Atenção" }
    public var healthWarningSubtitle: String { lang == .english ? "Heavy CPU load or low disk space detected." : "Carga pesada de CPU ou espaço reduzido detectado." }
    
    public var diskFreeSummary: String { lang == .english ? "Disk: %d%% free" : "Disco: %d%% livre" }
    public var ramUsedSummary: String { lang == .english ? "RAM: %d%% used" : "RAM: %d%% em uso" }
    public var cpuAlertSummary: String { lang == .english ? "CPU Alert" : "CPU em Alerta" }
    
    public var optimizeMac: String { lang == .english ? "Optimize Mac" : "Otimizar Mac" }
    public var optimizing: String { lang == .english ? "Optimizing..." : "Otimizando..." }
    public var quickOptimize: String { lang == .english ? "Quick Optimize" : "Otimização Rápida" }
    
    public var macintoshHD: String { "Macintosh HD" }
    public var percentUsed: String { lang == .english ? "%d%% in use" : "%d%% em uso" }
    public var freeOfTotal: String { lang == .english ? "free of %@" : "livres de %@" }
    public var examineDeepClean: String { lang == .english ? "Examine Deep Clean" : "Examinar Limpeza Profunda" }
    
    public var ramMemory: String { lang == .english ? "RAM Memory" : "Memória RAM" }
    public var percentOccupied: String { lang == .english ? "%d%% occupied" : "%d%% ocupada" }
    public var availableOfTotal: String { lang == .english ? "available of %@" : "disponíveis de %@" }
    public var activeRam: String { lang == .english ? "Active" : "Ativa" }
    public var wiredRam: String { lang == .english ? "Wired" : "Com Fio" }
    public var compressedRam: String { lang == .english ? "Compressed" : "Comprimida" }
    
    public var uptime: String { lang == .english ? "System Uptime" : "Tempo Ativo" }
    public var processor: String { lang == .english ? "Processor" : "Processador" }
    public var osVersion: String { lang == .english ? "OS Version" : "Sistema" }
    public var processesCount: String { lang == .english ? "%d monitored" : "%d monitorados" }
    public var processesTitle: String { lang == .english ? "Processes" : "Processos" }
    
    // MARK: - Deep Clean
    public var potentialSpaceToReclaim: String { lang == .english ? "Potential Space to Reclaim" : "Espaço Potencial a Recuperar" }
    public var deepCleanSubtitle: String {
        lang == .english
            ? "Selected items will be safely eliminated to free up your SSD."
            : "Itens selecionados serão eliminados com segurança para liberar seu SSD."
    }
    public var rescan: String { lang == .english ? "Rescan" : "Reescanear" }
    public var scanning: String { lang == .english ? "Scanning..." : "Analisando..." }
    public var selectAll: String { lang == .english ? "Select All" : "Marcar Todos" }
    public var deselect: String { lang == .english ? "Deselect" : "Desmarcar" }
    public var runDeepClean: String { lang == .english ? "Run Deep Clean" : "Executar Limpeza Profunda" }
    
    public func categoryTitle(for key: String) -> String {
        switch key {
        case "app_caches": return lang == .english ? "Application & Web Caches" : "Caches de Aplicativos & Web"
        case "installers": return lang == .english ? "Residual Installers (.dmg, .pkg)" : "Instaladores Residuais (.dmg, .pkg)"
        case "system_logs": return lang == .english ? "System Logs & Reports" : "Logs e Relatórios do Sistema"
        case "trash_temp": return lang == .english ? "Trash & Temporary Files" : "Lixeira & Arquivos Temporários"
        case "developer_caches": return lang == .english ? "Developer Caches (Xcode)" : "Caches de Desenvolvimento (Xcode)"
        case "project_builds": return lang == .english ? "Project Builds & Caches (.next, dist, pycache)" : "Builds e Caches de Projetos (.next, dist, pycache)"
        default: return key
        }
    }
    
    public func categorySubtitle(for key: String) -> String {
        switch key {
        case "app_caches":
            return lang == .english
                ? "Browsers (Chrome, Safari, Arc), Spotify, Slack and apps"
                : "Navegadores (Chrome, Safari, Arc), Spotify, Slack e apps"
        case "installers":
            return lang == .english
                ? "Disk images and packages left behind in Downloads"
                : "Imagens de disco e pacotes esquecidos em Downloads"
        case "system_logs":
            return lang == .english
                ? "Diagnostic history, app crashes and old logs"
                : "Histórico de diagnósticos, falhas de apps e logs antigos"
        case "trash_temp":
            return lang == .english
                ? "macOS Trash and residual temporary session files"
                : "Lixeira do macOS e arquivos residuais de sessão"
        case "developer_caches":
            return lang == .english
                ? "Xcode DerivedData and build artifacts"
                : "DerivedData do Xcode e artefatos de compilação"
        case "project_builds":
            return lang == .english
                ? "Next.js (.next), build bundles (dist), Swift (.build) and __pycache__"
                : "Next.js (.next), saídas de compilação (dist), Swift (.build) e __pycache__"
        default: return ""
        }
    }
    
    // MARK: - Processes & CPU
    public var highCPULoadAlert: String { lang == .english ? "Process Overloading CPU!" : "Processo Sobrecarregando a CPU!" }
    public func highCPUSubtitle(name: String, percent: Double) -> String {
        lang == .english
            ? "\(name) is consuming \(String(format: "%.1f", percent))% CPU in the background"
            : "\(name) está usando \(String(format: "%.1f", percent))% de CPU em segundo plano"
    }
    public var endNow: String { lang == .english ? "End Task" : "Encerrar Agora" }
    public var filterPlaceholder: String { lang == .english ? "Filter by name or PID..." : "Filtrar por nome ou PID..." }
    public var refreshList: String { lang == .english ? "Refresh List" : "Atualizar Lista" }
    public var colProcess: String { lang == .english ? "PROCESS" : "PROCESSO" }
    public var colPID: String { "PID" }
    public var colCPU: String { "CPU" }
    public var colActions: String { lang == .english ? "ACTIONS" : "AÇÕES" }
    public var noProcessesFound: String { lang == .english ? "No processes found." : "Nenhum processo encontrado." }
    public var readingProcesses: String { lang == .english ? "Reading system processes..." : "Lendo processos do sistema..." }
    public var killProcessTitle: String { lang == .english ? "Terminate Process?" : "Finalizar Processo?" }
    public func killProcessMessage(name: String, pid: Int, cpu: Double) -> String {
        lang == .english
            ? "Do you want to force terminate '\(name)' (PID \(pid)) which is using \(String(format: "%.1f", cpu))% CPU?"
            : "Deseja encerrar '\(name)' (PID \(pid)) que está consumindo \(String(format: "%.1f", cpu))% de CPU?"
    }
    public var terminateButton: String { lang == .english ? "Terminate Process" : "Encerrar Processo" }
    
    // MARK: - Quick Tools
    public var toolQuickCacheTitle: String { lang == .english ? "Clean Quick Caches" : "Limpar Caches Rápidos" }
    public var toolQuickCacheSubtitle: String {
        lang == .english
            ? "Removes temporary files from browsers (Chrome, Safari, Arc) and common apps."
            : "Remove arquivos temporários de navegadores (Chrome, Safari, Arc) e apps comuns."
    }
    public var toolQuickCacheButton: String { lang == .english ? "Clean Caches" : "Limpar Caches" }
    public var toolQuickCacheCleaning: String { lang == .english ? "Cleaning..." : "Limpando..." }
    
    public var toolEmptyTrashTitle: String { lang == .english ? "Empty Trash" : "Esvaziar Lixeira" }
    public var toolEmptyTrashSubtitle: String {
        lang == .english
            ? "Safely empties all items in the macOS user trash via Finder."
            : "Esvazia com segurança todos os itens na lixeira do usuário do macOS."
    }
    public var toolEmptyTrashButton: String { lang == .english ? "Empty Now" : "Esvaziar Agora" }
    
    public var toolFlushDNSTitle: String { lang == .english ? "Flush DNS Cache" : "Renovar Cache de DNS" }
    public var toolFlushDNSSubtitle: String {
        lang == .english
            ? "Runs dscacheutil and restarts mDNSResponder to fix network slowdowns."
            : "Executa dscacheutil e reinicia mDNSResponder para sanar lentidões de rede."
    }
    public var toolFlushDNSButton: String { lang == .english ? "Flush DNS" : "Limpar DNS" }
    public var toolFlushDNSFlushing: String { lang == .english ? "Flushing..." : "Renovando..." }
    
    public var toolFullOptimizeTitle: String { lang == .english ? "Full Optimization" : "Otimização Completa" }
    public var toolFullOptimizeSubtitle: String {
        lang == .english
            ? "Runs quick cache clean, DNS flush and instant memory update in one go."
            : "Executa a limpeza rápida, renovação de DNS e atualização instantânea de memória."
    }
    public var toolFullOptimizeButton: String { lang == .english ? "Run All" : "Executar Tudo" }
    
    // MARK: - Settings
    public var languageSection: String { lang == .english ? "Language / Idioma" : "Idioma / Language" }
    public var displayPreferences: String { lang == .english ? "Display Preferences" : "Preferências de Exibição" }
    public var keepInDockTitle: String { lang == .english ? "Keep icon in macOS Dock" : "Manter ícone no Dock do macOS" }
    public var keepInDockSubtitle: String {
        lang == .english
            ? "Allows switching to CleanBar with Command + Tab and keeping dock presence."
            : "Permite alternar para o CleanBar com Command + Tab e manter presença no Dock."
    }
    public var showMenubarTitle: String { lang == .english ? "Show free space in Menu Bar" : "Mostrar espaço livre na Barra de Menus" }
    public var showMenubarSubtitle: String {
        lang == .english
            ? "Displays the amount of free GB right next to the status icon."
            : "Exibe a quantidade de GB livres logo ao lado do ícone na barra de status superior."
    }
    public var startWithMacTitle: String { lang == .english ? "Start Automatically with Mac" : "Iniciar Automaticamente com o Mac" }
    public var startWithMacSubtitle: String {
        lang == .english
            ? "To let CleanBar monitor your storage right from system startup:"
            : "Para que o CleanBar monitore seu armazenamento desde a inicialização:"
    }
    public var step1: String { lang == .english ? "1. Open macOS **System Settings**." : "1. Abra os **Ajustes do Sistema** do macOS." }
    public var step2: String { lang == .english ? "2. Go to **General** > **Login Items**." : "2. Acesse **Geral** > **Itens de Início**." }
    public var step3: String { lang == .english ? "3. Click `+` and choose **CleanBar**." : "3. Clique em `+` e selecione o aplicativo **CleanBar**." }
    public var aboutCleanBar: String { lang == .english ? "About CleanBar" : "Sobre o CleanBar" }
    public var nativeBadge: String { lang == .english ? "Native • Swift 6.4 + SwiftUI + AppKit • Zero Electron" : "Nativo • Swift 6.4 + SwiftUI + AppKit • Sem Electron" }
    public var mitLicense: String { lang == .english ? "Distributed under the MIT Open Source License." : "Distribuído sob a licença MIT Open Source." }
    public var githubRepo: String { lang == .english ? "GitHub Repository" : "Repositório GitHub" }
    
    // MARK: - Permissions
    public var permissionsSection: String { lang == .english ? "System Permissions & Privacy" : "Permissões do Sistema & Privacidade" }
    public var permissionsDescription: String {
        lang == .english
            ? "Grant permission once so CleanBar can scan caches and trash silently without repeated macOS prompts."
            : "Conceda permissão uma única vez para o CleanBar analisar caches e lixeira silenciosamente, sem confirmações repetidas do macOS."
    }
    public var fullDiskAccessTitle: String { lang == .english ? "Full Disk Access (Recommended)" : "Acesso Total ao Disco (Recomendado)" }
    public var fullDiskAccessSubtitle: String {
        lang == .english
            ? "Enables complete, silent analysis of all caches, logs, and downloads with zero popups."
            : "Permite a análise completa e silenciosa de todos os caches, logs e instaladores sem janelas de confirmação."
    }
    public var openSettingsButton: String { lang == .english ? "Open System Settings" : "Abrir Ajustes do Sistema" }
    public var downloadsAccessTitle: String { lang == .english ? "Downloads Folder Access" : "Acesso à Pasta Downloads" }
    public var downloadsAccessSubtitle: String {
        lang == .english
            ? "Required to detect and clean residual .dmg and .pkg installers."
            : "Necessário para identificar e limpar instaladores residuais (.dmg e .pkg)."
    }
    public var grantedBadge: String { lang == .english ? "Granted" : "Concedido" }
    public var notGrantedBadge: String { lang == .english ? "Not Configured" : "Não Configurado" }
    public var grantButton: String { lang == .english ? "Authorize" : "Autorizar" }
    public var permissionBannerTitle: String { lang == .english ? "💡 Silent 1-Time Setup" : "💡 Configuração de Permissão Única" }
    public var permissionBannerSubtitle: String {
        lang == .english
            ? "Enable 'Full Disk Access' once in System Settings so macOS never prompts for folder permissions again."
            : "Ative o 'Acesso Total ao Disco' uma vez nos Ajustes do Sistema para que o macOS nunca mais peça permissão de pastas."
    }
}
