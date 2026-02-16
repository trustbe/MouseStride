#!/usr/bin/env swift
// generate-icon.swift — Generates MouseStride.icns from SF Symbol
// Run: swift Scripts/generate-icon.swift
// Requires: macOS 11+, AppKit

import AppKit

// Icon sizes required for macOS .iconset
let iconSizes: [(name: String, size: Int)] = [
    ("icon_16x16",      16),
    ("icon_16x16@2x",   32),
    ("icon_32x32",      32),
    ("icon_32x32@2x",   64),
    ("icon_128x128",    128),
    ("icon_128x128@2x", 256),
    ("icon_256x256",    256),
    ("icon_256x256@2x", 512),
    ("icon_512x512",    512),
    ("icon_512x512@2x", 1024),
]

func renderIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = CGFloat(size) * 0.22 // macOS icon corner radius proportion

    // Rounded-rect background with gradient
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    let gradient = NSGradient(
        starting: NSColor(calibratedRed: 0.25, green: 0.55, blue: 0.95, alpha: 1.0),
        ending:   NSColor(calibratedRed: 0.15, green: 0.35, blue: 0.75, alpha: 1.0)
    )!
    gradient.draw(in: path, angle: -90)

    // Subtle inner shadow / border for depth
    let borderPath = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor(white: 1.0, alpha: 0.15).setStroke()
    borderPath.lineWidth = 1.0
    borderPath.stroke()

    // SF Symbol
    let config = NSImage.SymbolConfiguration(pointSize: CGFloat(size) * 0.5, weight: .medium)
    if let symbol = NSImage(systemSymbolName: "computermouse.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {

        // Tint the symbol white
        let tinted = NSImage(size: symbol.size)
        tinted.lockFocus()
        NSColor.white.set()
        let symbolRect = NSRect(origin: .zero, size: symbol.size)
        symbol.draw(in: symbolRect)
        symbolRect.fill(using: .sourceAtop)
        tinted.unlockFocus()

        // Center the symbol in the icon
        let symbolSize = tinted.size
        let x = (CGFloat(size) - symbolSize.width) / 2
        let y = (CGFloat(size) - symbolSize.height) / 2
        tinted.draw(
            in: NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0
        )
    }

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("ERROR: Failed to create PNG for \(path)")
        exit(1)
    }
    do {
        try pngData.write(to: URL(fileURLWithPath: path))
    } catch {
        print("ERROR: Failed to write \(path): \(error)")
        exit(1)
    }
}

// Resolve paths relative to the script's repo root
let scriptDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
let repoRoot = scriptDir.deletingLastPathComponent()
let iconsetDir = repoRoot.appendingPathComponent("MouseStride.iconset")
let resourcesDir = repoRoot.appendingPathComponent("Sources/MouseStride/Resources")
let icnsPath = resourcesDir.appendingPathComponent("MouseStride.icns")

// Create directories
let fm = FileManager.default
try? fm.createDirectory(at: iconsetDir, withIntermediateDirectories: true)
try? fm.createDirectory(at: resourcesDir, withIntermediateDirectories: true)

print("Generating icon PNGs into \(iconsetDir.path)...")

for entry in iconSizes {
    let image = renderIcon(size: entry.size)
    let path = iconsetDir.appendingPathComponent("\(entry.name).png").path
    savePNG(image, to: path)
    print("  \(entry.name).png (\(entry.size)x\(entry.size))")
}

print("Converting to .icns...")

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsPath.path]
try process.run()
process.waitUntilExit()

if process.terminationStatus != 0 {
    print("ERROR: iconutil failed with exit code \(process.terminationStatus)")
    exit(1)
}

// Clean up iconset directory
try? fm.removeItem(at: iconsetDir)

print("Done! Icon saved to \(icnsPath.path)")
