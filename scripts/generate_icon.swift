import Cocoa
import AppKit

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    exit(1)
}

// 1. Draw rounded squircle base
let rect = CGRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 190
let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

// Shadow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -30), blur: 60, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))
ctx.addPath(path)
ctx.setFillColor(CGColor(red: 0.08, green: 0.09, blue: 0.14, alpha: 1.0))
ctx.fillPath()
ctx.restoreGState()

// Base Gradient inside Squircle
ctx.saveGState()
ctx.addPath(path)
ctx.clip()

let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradientColors = [
    CGColor(red: 0.07, green: 0.12, blue: 0.22, alpha: 1.0),
    CGColor(red: 0.04, green: 0.06, blue: 0.12, alpha: 1.0)
] as CFArray

if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0]) {
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 100, y: 924), end: CGPoint(x: 924, y: 100), options: [])
}

// Radial Glow from center
let glowColors = [
    CGColor(red: 0.1, green: 0.7, blue: 0.9, alpha: 0.35),
    CGColor(red: 0.5, green: 0.2, blue: 0.9, alpha: 0.15),
    CGColor(red: 0, green: 0, blue: 0, alpha: 0.0)
] as CFArray
if let radialGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 0.45, 1.0]) {
    ctx.drawRadialGradient(radialGrad, startCenter: CGPoint(x: 512, y: 512), startRadius: 0, endCenter: CGPoint(x: 512, y: 512), endRadius: 420, options: [])
}

// Specular rim stroke
ctx.setLineWidth(10)
ctx.setStrokeColor(CGColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 0.35))
ctx.addPath(path)
ctx.strokePath()

ctx.restoreGState()

// 2. Draw Symbol (Sparkles)
let config = NSImage.SymbolConfiguration(pointSize: 340, weight: .bold)
if let sfImage = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
    let tintColor = NSColor(calibratedRed: 0.2, green: 0.85, blue: 1.0, alpha: 1.0)
    
    // Draw shadow behind sparkles
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: 0), blur: 40, color: CGColor(red: 0.1, green: 0.8, blue: 1.0, alpha: 0.75))
    
    let iconRect = NSRect(x: (1024 - sfImage.size.width) / 2, y: (1024 - sfImage.size.height) / 2 + 10, width: sfImage.size.width, height: sfImage.size.height)
    
    // Tint the image
    let tinted = NSImage(size: sfImage.size)
    tinted.lockFocus()
    tintColor.set()
    NSRect(origin: .zero, size: sfImage.size).fill()
    sfImage.draw(at: .zero, from: .zero, operation: .destinationIn, fraction: 1.0)
    tinted.unlockFocus()
    
    tinted.draw(in: iconRect)
    ctx.restoreGState()
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    exit(1)
}

let outURL = URL(fileURLWithPath: "assets/AppIcon_1024.png")
try? png.write(to: outURL)
print("Generated assets/AppIcon_1024.png")
