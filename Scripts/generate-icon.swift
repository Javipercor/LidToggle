import AppKit

// Vector artwork rendered at every macOS icon size; no external assets required.
let output = CommandLine.arguments.dropFirst().first ?? "build/LidToggle.iconset"
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)

func render(_ pixels: Int) throws -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let scale = CGFloat(pixels) / 1024
    let transform = NSAffineTransform()
    transform.scale(by: scale)
    transform.concat()

    let tile = NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 200, yRadius: 200)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -14)
    shadow.set()
    NSColor(calibratedRed: 0.10, green: 0.15, blue: 0.38, alpha: 1).setFill()
    tile.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(colors: [NSColor(calibratedRed: 0.24, green: 0.39, blue: 0.85, alpha: 1),
                        NSColor(calibratedRed: 0.08, green: 0.12, blue: 0.31, alpha: 1)])!
        .draw(in: tile, angle: -70)

    func symbol(_ name: String, rect: NSRect, color: NSColor) {
        let config = NSImage.SymbolConfiguration(pointSize: 400, weight: .medium)
            .applying(.init(paletteColors: [color]))
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)!
            .withSymbolConfiguration(config)!
        let ratio = min(rect.width / image.size.width, rect.height / image.size.height)
        let size = NSSize(width: image.size.width * ratio, height: image.size.height * ratio)
        image.draw(in: NSRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2,
                              width: size.width, height: size.height))
    }

    symbol("moon.fill", rect: NSRect(x: 220, y: 240, width: 460, height: 520),
           color: NSColor(calibratedRed: 0.91, green: 0.96, blue: 1, alpha: 1))
    symbol("sun.max.fill", rect: NSRect(x: 548, y: 494, width: 260, height: 260),
           color: NSColor(calibratedRed: 1, green: 0.76, blue: 0.28, alpha: 1))

    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    for factor in [1, 2] {
        let suffix = factor == 2 ? "@2x" : ""
        let path = "\(output)/icon_\(size)x\(size)\(suffix).png"
        try render(size * factor).write(to: URL(fileURLWithPath: path))
    }
}
