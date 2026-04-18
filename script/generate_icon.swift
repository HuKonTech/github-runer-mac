import AppKit

let fm = FileManager.default
let root = URL(fileURLWithPath: fm.currentDirectoryPath)
let assetsDir = root.appendingPathComponent("Assets", isDirectory: true)
let iconsetDir = assetsDir.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let basePNG = assetsDir.appendingPathComponent("AppIcon-1024.png")

try? fm.removeItem(at: iconsetDir)
try fm.createDirectory(at: iconsetDir, withIntermediateDirectories: true)
try fm.createDirectory(at: assetsDir, withIntermediateDirectories: true)

func makeImage(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.22

    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.35)
    shadow.shadowBlurRadius = size * 0.05
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.015)
    shadow.set()

    let bg = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.08, dy: size * 0.08), xRadius: radius, yRadius: radius)
    bg.addClip()

    let bgGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.30, green: 0.39, blue: 0.54, alpha: 1),
        NSColor(calibratedRed: 0.07, green: 0.12, blue: 0.20, alpha: 1),
    ])!
    bgGradient.draw(in: bg, angle: 235)

    let lowerGlowRect = CGRect(x: size * 0.44, y: size * 0.11, width: size * 0.42, height: size * 0.36)
    let lowerGlow = NSBezierPath(ovalIn: lowerGlowRect)
    NSColor(calibratedRed: 0.12, green: 0.92, blue: 0.76, alpha: 0.35).setFill()
    lowerGlow.fill()

    let coreRect = CGRect(x: size * 0.18, y: size * 0.19, width: size * 0.58, height: size * 0.58)
    let core = NSBezierPath(ovalIn: coreRect)
    let coreGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.78, green: 0.95, blue: 0.96, alpha: 1),
        NSColor(calibratedRed: 0.23, green: 0.55, blue: 0.76, alpha: 1),
        NSColor(calibratedRed: 0.06, green: 0.14, blue: 0.31, alpha: 1),
    ])!
    coreGradient.draw(in: core, relativeCenterPosition: NSPoint(x: -0.2, y: 0.2))

    ctx.saveGState()
    core.addClip()
    for idx in 0..<3 {
        let y = size * (0.47 + CGFloat(idx) * 0.08)
        let bar = NSBezierPath(roundedRect: CGRect(x: size * 0.30, y: y, width: size * 0.35, height: size * 0.028), xRadius: size * 0.014, yRadius: size * 0.014)
        NSColor(calibratedRed: 0.85, green: 0.98, blue: 1.0, alpha: 0.34 - CGFloat(idx) * 0.06).setFill()
        bar.fill()
    }
    ctx.restoreGState()

    let ringOuter = NSBezierPath(ovalIn: coreRect.insetBy(dx: -size * 0.02, dy: -size * 0.02))
    ringOuter.lineWidth = size * 0.018
    NSColor(calibratedRed: 0.16, green: 0.93, blue: 0.88, alpha: 0.75).setStroke()
    ringOuter.stroke()

    let ringInner = NSBezierPath(ovalIn: coreRect.insetBy(dx: size * 0.01, dy: size * 0.01))
    ringInner.lineWidth = size * 0.012
    NSColor(calibratedRed: 0.18, green: 0.73, blue: 1.0, alpha: 0.65).setStroke()
    ringInner.stroke()

    let play = NSBezierPath()
    play.move(to: CGPoint(x: size * 0.24, y: size * 0.43))
    play.line(to: CGPoint(x: size * 0.24, y: size * 0.60))
    play.line(to: CGPoint(x: size * 0.39, y: size * 0.515))
    play.close()
    let playGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.15, green: 0.63, blue: 1.0, alpha: 1),
        NSColor(calibratedRed: 0.45, green: 0.98, blue: 0.95, alpha: 1),
    ])!
    playGradient.draw(in: play, angle: 20)

    let runner = NSBezierPath()
    runner.move(to: CGPoint(x: size * 0.54, y: size * 0.63))
    runner.curve(to: CGPoint(x: size * 0.60, y: size * 0.61), controlPoint1: CGPoint(x: size * 0.57, y: size * 0.66), controlPoint2: CGPoint(x: size * 0.60, y: size * 0.65))
    runner.line(to: CGPoint(x: size * 0.66, y: size * 0.57))
    runner.curve(to: CGPoint(x: size * 0.70, y: size * 0.54), controlPoint1: CGPoint(x: size * 0.68, y: size * 0.57), controlPoint2: CGPoint(x: size * 0.70, y: size * 0.56))
    runner.line(to: CGPoint(x: size * 0.63, y: size * 0.49))
    runner.line(to: CGPoint(x: size * 0.58, y: size * 0.40))
    runner.line(to: CGPoint(x: size * 0.54, y: size * 0.28))
    runner.curve(to: CGPoint(x: size * 0.48, y: size * 0.28), controlPoint1: CGPoint(x: size * 0.53, y: size * 0.26), controlPoint2: CGPoint(x: size * 0.50, y: size * 0.26))
    runner.line(to: CGPoint(x: size * 0.52, y: size * 0.43))
    runner.line(to: CGPoint(x: size * 0.45, y: size * 0.52))
    runner.line(to: CGPoint(x: size * 0.38, y: size * 0.51))
    runner.line(to: CGPoint(x: size * 0.33, y: size * 0.40))
    runner.curve(to: CGPoint(x: size * 0.28, y: size * 0.36), controlPoint1: CGPoint(x: size * 0.32, y: size * 0.37), controlPoint2: CGPoint(x: size * 0.30, y: size * 0.35))
    runner.line(to: CGPoint(x: size * 0.26, y: size * 0.32))
    runner.curve(to: CGPoint(x: size * 0.34, y: size * 0.31), controlPoint1: CGPoint(x: size * 0.27, y: size * 0.30), controlPoint2: CGPoint(x: size * 0.32, y: size * 0.30))
    runner.line(to: CGPoint(x: size * 0.44, y: size * 0.36))
    runner.line(to: CGPoint(x: size * 0.54, y: size * 0.36))
    runner.line(to: CGPoint(x: size * 0.62, y: size * 0.46))
    runner.line(to: CGPoint(x: size * 0.69, y: size * 0.44))
    runner.curve(to: CGPoint(x: size * 0.72, y: size * 0.48), controlPoint1: CGPoint(x: size * 0.71, y: size * 0.44), controlPoint2: CGPoint(x: size * 0.72, y: size * 0.46))
    runner.line(to: CGPoint(x: size * 0.61, y: size * 0.57))
    runner.line(to: CGPoint(x: size * 0.56, y: size * 0.51))
    runner.line(to: CGPoint(x: size * 0.50, y: size * 0.56))
    runner.curve(to: CGPoint(x: size * 0.47, y: size * 0.60), controlPoint1: CGPoint(x: size * 0.49, y: size * 0.58), controlPoint2: CGPoint(x: size * 0.48, y: size * 0.60))
    runner.close()
    NSColor(calibratedRed: 0.02, green: 0.05, blue: 0.12, alpha: 0.96).setFill()
    runner.fill()

    let head = NSBezierPath(ovalIn: CGRect(x: size * 0.49, y: size * 0.56, width: size * 0.13, height: size * 0.13))
    NSColor(calibratedRed: 0.02, green: 0.05, blue: 0.12, alpha: 0.98).setFill()
    head.fill()

    let ear1 = NSBezierPath()
    ear1.move(to: CGPoint(x: size * 0.52, y: size * 0.68))
    ear1.line(to: CGPoint(x: size * 0.54, y: size * 0.74))
    ear1.line(to: CGPoint(x: size * 0.57, y: size * 0.69))
    ear1.close()
    ear1.fill()

    let ear2 = NSBezierPath()
    ear2.move(to: CGPoint(x: size * 0.60, y: size * 0.68))
    ear2.line(to: CGPoint(x: size * 0.64, y: size * 0.72))
    ear2.line(to: CGPoint(x: size * 0.65, y: size * 0.67))
    ear2.close()
    ear2.fill()

    let node1 = NSBezierPath(ovalIn: CGRect(x: size * 0.66, y: size * 0.47, width: size * 0.08, height: size * 0.08))
    NSColor(calibratedRed: 0.07, green: 0.70, blue: 1.0, alpha: 1).setFill()
    node1.fill()

    let node2 = NSBezierPath(ovalIn: CGRect(x: size * 0.74, y: size * 0.58, width: size * 0.08, height: size * 0.08))
    NSColor(calibratedRed: 0.38, green: 0.97, blue: 0.80, alpha: 1).setFill()
    node2.fill()

    let link = NSBezierPath()
    link.move(to: CGPoint(x: size * 0.71, y: size * 0.51))
    link.line(to: CGPoint(x: size * 0.78, y: size * 0.60))
    link.move(to: CGPoint(x: size * 0.61, y: size * 0.51))
    link.line(to: CGPoint(x: size * 0.76, y: size * 0.51))
    link.lineWidth = size * 0.012
    NSColor(calibratedRed: 0.28, green: 0.92, blue: 0.86, alpha: 0.9).setStroke()
    link.stroke()

    let rim = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.08, dy: size * 0.08), xRadius: radius, yRadius: radius)
    rim.lineWidth = size * 0.006
    NSColor(calibratedWhite: 1.0, alpha: 0.18).setStroke()
    rim.stroke()

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let png = rep.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "GenerateIcon", code: 1)
    }

    try png.write(to: url)
}

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, size) in sizes {
    let image = makeImage(size: size)
    try writePNG(image, to: iconsetDir.appendingPathComponent(name))
    if size == 1024 {
        try writePNG(image, to: basePNG)
    }
}

print("Generated iconset at \(iconsetDir.path)")
