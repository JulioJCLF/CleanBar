import SwiftUI
import AppKit
import QuartzCore

// MARK: - Hardware-Accelerated Pulsing Glow (GPU Metal Compositor, 0% CPU, Zero Macros)
public struct PulsingGlowView<Content: View>: NSViewRepresentable {
    public let content: Content
    public let color: NSColor
    
    public init(color: Color = .red, @ViewBuilder content: () -> Content) {
        self.color = NSColor(color)
        self.content = content()
    }
    
    public func makeNSView(context: Context) -> NSHostingView<Content> {
        let host = NSHostingView(rootView: content)
        host.wantsLayer = true
        
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = 0.4
        anim.toValue = 1.0
        anim.duration = 0.85
        anim.autoreverses = true
        anim.repeatCount = .infinity
        anim.isRemovedOnCompletion = false
        host.layer?.add(anim, forKey: "cleanbar.pulse")
        
        return host
    }
    
    public func updateNSView(_ nsView: NSHostingView<Content>, context: Context) {
        nsView.rootView = content
    }
}

// MARK: - Hardware-Accelerated Continuous Spin (GPU Metal Compositor, 0% CPU, Zero Macros)
public struct ContinuousSpinView<Content: View>: NSViewRepresentable {
    public let content: Content
    public let duration: Double
    
    public init(duration: Double = 1.2, @ViewBuilder content: () -> Content) {
        self.duration = max(0.1, duration)
        self.content = content()
    }
    
    public init(speed: Double = 180, @ViewBuilder content: () -> Content) {
        self.duration = 360.0 / max(0.1, speed)
        self.content = content()
    }
    
    public func makeNSView(context: Context) -> NSHostingView<Content> {
        let host = NSHostingView(rootView: content)
        host.wantsLayer = true
        
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.fromValue = 0.0
        anim.toValue = -Double.pi * 2.0
        anim.duration = duration
        anim.repeatCount = .infinity
        anim.isRemovedOnCompletion = false
        host.layer?.add(anim, forKey: "cleanbar.spin")
        
        return host
    }
    
    public func updateNSView(_ nsView: NSHostingView<Content>, context: Context) {
        nsView.rootView = content
    }
}

// MARK: - Interactive Button Styles (Zero Macros)
public struct InteractiveCardButtonStyle: ButtonStyle {
    public var glowColor: Color
    
    public init(glowColor: Color = .cyan) {
        self.glowColor = glowColor
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(
                color: glowColor.opacity(configuration.isPressed ? 0.35 : 0.06),
                radius: configuration.isPressed ? 12 : 4,
                x: 0,
                y: configuration.isPressed ? 2 : 2
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

public struct InteractivePillButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Circular Gauge Ring View
public struct GaugeRingView: View {
    public var percentage: Int
    public var lineWidth: CGFloat = 10
    public var gradient: LinearGradient = LinearGradient(
        colors: [.cyan, .blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    public var shadowColor: Color = .cyan
    public var showLabel: Bool = true
    public var labelFont: Font = .system(size: 20, weight: .heavy, design: .rounded)
    
    public init(
        percentage: Int,
        lineWidth: CGFloat = 10,
        gradient: LinearGradient = LinearGradient(
            colors: [.cyan, .blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        shadowColor: Color = .cyan,
        showLabel: Bool = true,
        labelFont: Font = .system(size: 20, weight: .heavy, design: .rounded)
    ) {
        self.percentage = min(100, max(0, percentage))
        self.lineWidth = lineWidth
        self.gradient = gradient
        self.shadowColor = shadowColor
        self.showLabel = showLabel
        self.labelFont = labelFont
    }
    
    private var progress: CGFloat {
        CGFloat(percentage) / 100.0
    }
    
    public var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
            
            // Progress Bar
            Circle()
                .trim(from: 0, to: max(0.02, progress))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: shadowColor.opacity(0.4), radius: 6, x: 0, y: 0)
                .animation(.spring(response: 0.75, dampingFraction: 0.75), value: progress)
            
            if showLabel {
                VStack(spacing: 0) {
                    Text("\(percentage)%")
                        .font(labelFont)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
            }
        }
    }
}

// MARK: - View Extension Helpers
extension View {
    public func pulsingGlow(color: Color = .red) -> some View {
        PulsingGlowView(color: color) {
            self
        }
    }
    
    public func continuousSpin(duration: Double = 1.2) -> some View {
        ContinuousSpinView(duration: duration) {
            self
        }
    }
    
    public func hoverLift(elevation: CGFloat = 2, scale: CGFloat = 1.005) -> some View {
        self
            .shadow(color: Color.black.opacity(0.04), radius: elevation, x: 0, y: 1)
    }
    
    public func polishedGlassCard(cornerRadius: CGFloat = 14) -> some View {
        self
            .background(
                Color.primary.opacity(0.04),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
    }
    
    public func polishedGlassButton(cornerRadius: CGFloat = 10, isHighlighted: Bool = false) -> some View {
        self
            .background(
                isHighlighted ? Color.cyan.opacity(0.15) : Color.primary.opacity(0.06),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        isHighlighted ? Color.cyan.opacity(0.4) : Color.white.opacity(0.14),
                        lineWidth: 0.8
                    )
            )
    }
}
