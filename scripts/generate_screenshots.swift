import SwiftUI
import AppKit

struct DesktopWindowContainer: View {
    var body: some View {
        ZStack {
            // Subtle dark wallpaper background to show off glassmorphism and window shadows
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.09, blue: 0.14), Color(red: 0.11, green: 0.07, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 900, height: 660)
            
            CleanBarMainWindowView()
                .frame(width: 820, height: 580)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.45), radius: 28, x: 0, y: 16)
        }
        .frame(width: 900, height: 660)
    }
}

struct PopoverContainer: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.09, blue: 0.14), Color(red: 0.11, green: 0.07, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 440, height: 600)
            
            CleanBarView()
                .frame(width: 350)
                .padding(30)
                .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .frame(width: 440, height: 600)
    }
}

@main
struct ScreenshotGenerator {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        
        let container = DesktopWindowContainer()
        let basePath = "/Users/jclf/Documents/Projects/CleanBar/assets"
        
        // 1. Dashboard Tab
        AppState.shared.selectedTab = .dashboard
        AppState.shared.refreshDisk()
        AppState.shared.refreshMemory()
        let renderer1 = ImageRenderer(content: container)
        renderer1.scale = 2.0
        if let img1 = renderer1.nsImage {
            savePNG(image: img1, path: "\(basePath)/cleanbar-dashboard.png")
        }
        
        // 2. Deep Clean Tab
        AppState.shared.selectedTab = .deepClean
        AppState.shared.deepCleanCategories = DeepCleaner.shared.scanCategories()
        AppState.shared.totalRecoverableBytes = AppState.shared.deepCleanCategories.reduce(0) { $0 + $1.estimatedSizeBytes }
        let renderer2 = ImageRenderer(content: container)
        renderer2.scale = 2.0
        if let img2 = renderer2.nsImage {
            savePNG(image: img2, path: "\(basePath)/cleanbar-deepclean.png")
        }
        
        // 3. Processes Tab
        AppState.shared.selectedTab = .processes
        AppState.shared.topProcesses = ProcessMonitor.shared.fetchTopProcesses(limit: 10)
        AppState.shared.hasHighCPUProcess = AppState.shared.topProcesses.contains { $0.isHighCPU && !$0.isSystemCritical }
        let renderer3 = ImageRenderer(content: container)
        renderer3.scale = 2.0
        if let img3 = renderer3.nsImage {
            savePNG(image: img3, path: "\(basePath)/cleanbar-processes.png")
        }
        
        // 4. Settings & Permissions Tab
        AppState.shared.selectedTab = .settings
        let renderer4 = ImageRenderer(content: container)
        renderer4.scale = 2.0
        if let img4 = renderer4.nsImage {
            savePNG(image: img4, path: "\(basePath)/cleanbar-settings.png")
        }
        
        // 5. Menu Bar Popover
        AppState.shared.selectedTab = .dashboard
        let popoverRenderer = ImageRenderer(content: PopoverContainer())
        popoverRenderer.scale = 2.0
        if let popoverImg = popoverRenderer.nsImage {
            savePNG(image: popoverImg, path: "\(basePath)/cleanbar-menubar.png")
        }
        
        print("Done rendering all 5 screenshots (Dashboard, Deep Clean, Processes, Settings, Menubar)!")
    }
    
    @MainActor
    static func savePNG(image: NSImage, path: String) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            print("Failed to convert image to PNG")
            return
        }
        do {
            try pngData.write(to: URL(fileURLWithPath: path))
            print("Successfully saved screenshot to:", path)
        } catch {
            print("Error saving PNG:", error)
        }
    }
}
