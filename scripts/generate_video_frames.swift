import SwiftUI
import AppKit

struct MockMenuBar: View {
    let isIconHighlighted: Bool
    
    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 14) {
                // System items
                Image(systemName: "wifi")
                    .font(.system(size: 12))
                Image(systemName: "battery.100")
                    .font(.system(size: 13))
                Text("23:30")
                    .font(.system(size: 12, weight: .medium))
                
                // CleanBar status item
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isIconHighlighted ? .cyan : .primary)
                    Text("35.8 GB")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    isIconHighlighted ? Color.white.opacity(0.18) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6)
                )
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 20)
        }
        .frame(height: 28)
        .background(Color.black.opacity(0.35))
    }
}

struct ShowcaseScene: View {
    let frameIndex: Int
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // macOS Sonoma / Sequoia style dark wallpaper
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.09, blue: 0.15),
                    Color(red: 0.13, green: 0.08, blue: 0.18),
                    Color(red: 0.05, green: 0.07, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(alignment: .trailing, spacing: 6) {
                MockMenuBar(isIconHighlighted: frameIndex >= 10)
                
                if frameIndex >= 10 {
                    // Popover drop in animation
                    let progress = min(1.0, Double(frameIndex - 10) / 12.0)
                    let scale = 0.92 + (0.08 * progress)
                    let opacity = progress
                    
                    CleanBarView()
                        .frame(width: 350)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .padding(.trailing, 16)
                        .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
                }
            }
        }
        .frame(width: 580, height: 640)
    }
}

@main
struct VideoGenerator {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        
        let totalFrames = 150
        print("Rendering \(totalFrames) video frames...")
        try? FileManager.default.createDirectory(atPath: "/tmp/cleanbar_frames", withIntermediateDirectories: true)
        
        // Setup initial state
        AppState.shared.deepCleanCategories = DeepCleaner.shared.scanCategories()
        AppState.shared.totalRecoverableBytes = AppState.shared.deepCleanCategories.reduce(0) { $0 + $1.estimatedSizeBytes }
        AppState.shared.topProcesses = ProcessMonitor.shared.fetchTopProcesses(limit: 7)
        
        for i in 0..<totalFrames {
            // Animate states across time
            if i < 50 {
                AppState.shared.selectedTab = .dashboard
            } else if i < 100 {
                AppState.shared.selectedTab = .deepClean
            } else {
                AppState.shared.selectedTab = .processes
            }
            
            let scene = ShowcaseScene(frameIndex: i)
            let renderer = ImageRenderer(content: scene)
            renderer.scale = 1.0 // crisp 580x640
            
            if let image = renderer.nsImage {
                saveFrame(image: image, index: i)
            }
            
            if i % 30 == 0 {
                print("Rendered frame \(i)/\(totalFrames)")
            }
        }
        
        print("Done rendering all \(totalFrames) frames!")
    }
    
    @MainActor
    static func saveFrame(image: NSImage, index: Int) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return
        }
        let fileName = String(format: "/tmp/cleanbar_frames/frame_%04d.png", index)
        try? pngData.write(to: URL(fileURLWithPath: fileName))
    }
}
