import SwiftUI
import AppKit

@main
struct ScreenshotGenerator {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        
        let view = ZStack {
            // Subtle dark wallpaper background to show off glassmorphism
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.10, blue: 0.16), Color(red: 0.12, green: 0.08, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 420, height: 600)
            
            CleanBarView()
                .frame(width: 350)
                .padding(35)
        }
        .frame(width: 420, height: 600)
        
        // 1. Dashboard Tab
        AppState.shared.selectedTab = .dashboard
        let renderer1 = ImageRenderer(content: view)
        renderer1.scale = 2.0
        if let img1 = renderer1.nsImage {
            savePNG(image: img1, path: "/Users/jclf/Documents/projects/CleanBar/assets/cleanbar-dashboard.png")
        }
        
        // 2. Deep Clean Tab
        AppState.shared.selectedTab = .deepClean
        AppState.shared.deepCleanCategories = DeepCleaner.shared.scanCategories()
        AppState.shared.totalRecoverableBytes = AppState.shared.deepCleanCategories.reduce(0) { $0 + $1.estimatedSizeBytes }
        let renderer2 = ImageRenderer(content: view)
        renderer2.scale = 2.0
        if let img2 = renderer2.nsImage {
            savePNG(image: img2, path: "/Users/jclf/Documents/projects/CleanBar/assets/cleanbar-deepclean.png")
        }
        
        // 3. Processes Tab
        AppState.shared.selectedTab = .processes
        AppState.shared.topProcesses = ProcessMonitor.shared.fetchTopProcesses(limit: 7)
        AppState.shared.hasHighCPUProcess = AppState.shared.topProcesses.contains { $0.isHighCPU && !$0.isSystemCritical }
        let renderer3 = ImageRenderer(content: view)
        renderer3.scale = 2.0
        if let img3 = renderer3.nsImage {
            savePNG(image: img3, path: "/Users/jclf/Documents/projects/CleanBar/assets/cleanbar-processes.png")
        }
        
        print("Done rendering all screenshots!")
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
