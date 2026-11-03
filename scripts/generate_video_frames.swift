import SwiftUI
import AppKit

struct DesktopWindowShowcase: View {
    let frameIndex: Int
    
    var body: some View {
        ZStack {
            // Elegant dark background wallpaper
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.13),
                    Color(red: 0.10, green: 0.06, blue: 0.15),
                    Color(red: 0.04, green: 0.06, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Standalone desktop window with smooth scale-in and shadow
            let scaleProgress = min(1.0, Double(frameIndex) / 10.0)
            let scale = 0.95 + (0.05 * scaleProgress)
            let opacity = min(1.0, Double(frameIndex) / 8.0)
            
            CleanBarMainWindowView()
                .frame(width: 820, height: 580)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: 18)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .frame(width: 880, height: 640)
    }
}

@main
struct VideoGenerator {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        
        let totalFrames = 140
        print("Rendering \(totalFrames) video frames of CleanBar Desktop App...")
        
        let framesDir = "/tmp/cleanbar_window_frames"
        try? FileManager.default.removeItem(atPath: framesDir)
        try? FileManager.default.createDirectory(atPath: framesDir, withIntermediateDirectories: true)
        
        // Setup mock data for rendering
        AppState.shared.deepCleanCategories = DeepCleaner.shared.scanCategories()
        AppState.shared.totalRecoverableBytes = AppState.shared.deepCleanCategories.reduce(0) { $0 + $1.estimatedSizeBytes }
        AppState.shared.topProcesses = ProcessMonitor.shared.fetchTopProcesses(limit: 10)
        AppState.shared.refreshDisk()
        AppState.shared.refreshMemory()
        
        for i in 0..<totalFrames {
            // Tab progression across timeline
            if i < 40 {
                AppState.shared.selectedTab = .dashboard
            } else if i < 75 {
                AppState.shared.selectedTab = .deepClean
            } else if i < 110 {
                AppState.shared.selectedTab = .processes
            } else {
                AppState.shared.selectedTab = .settings
            }
            
            let scene = DesktopWindowShowcase(frameIndex: i)
            let renderer = ImageRenderer(content: scene)
            renderer.scale = 1.0 // Crisp 880x640 resolution
            
            if let image = renderer.nsImage {
                saveFrame(image: image, index: i, dir: framesDir)
            }
            
            if i % 25 == 0 {
                print("Rendered frame \(i)/\(totalFrames)...")
            }
        }
        
        print("Done rendering all \(totalFrames) frames to \(framesDir)!")
    }
    
    @MainActor
    static func saveFrame(image: NSImage, index: Int, dir: String) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return
        }
        let fileName = String(format: "%@/frame_%04d.png", dir, index)
        try? pngData.write(to: URL(fileURLWithPath: fileName))
    }
}
