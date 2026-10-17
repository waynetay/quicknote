import AppKit
import Foundation

let source = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])
guard let image = NSImage(contentsOf: source) else {
    fatalError("Could not load app icon SVG at \(source.path)")
}
try? FileManager.default.removeItem(at: output)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]
for (name, size) in sizes {
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ) else { fatalError("Could not allocate icon bitmap") }
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    image.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode \(name)")
    }
    try data.write(to: output.appendingPathComponent(name))
}
