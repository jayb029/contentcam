import AppKit

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: render-dmg-background <output.png>\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let canvasSize = NSSize(width: 720, height: 440)

let image = NSImage(size: canvasSize, flipped: false) { bounds in
    let background = NSGradient(colors: [
        NSColor(red: 0.055, green: 0.071, blue: 0.102, alpha: 1),
        NSColor(red: 0.118, green: 0.157, blue: 0.220, alpha: 1),
    ])!
    background.draw(in: bounds, angle: -28)

    let glow = NSGradient(starting: NSColor(red: 0.23, green: 0.63, blue: 0.98, alpha: 0.20),
                          ending: .clear)!
    glow.draw(in: NSBezierPath(ovalIn: NSRect(x: 245, y: 205, width: 420, height: 420)),
              relativeCenterPosition: NSPoint(x: 0, y: 0))

    NSColor.white.withAlphaComponent(0.075).setStroke()
    for inset in stride(from: CGFloat(0), through: 54, by: 18) {
        let ring = NSBezierPath(ovalIn: NSRect(x: 583 + inset / 2,
                                               y: 329 + inset / 2,
                                               width: 92 - inset,
                                               height: 92 - inset))
        ring.lineWidth = 1
        ring.stroke()
    }

    let panelColor = NSColor.white.withAlphaComponent(0.065)
    for rect in [NSRect(x: 78, y: 96, width: 224, height: 200),
                 NSRect(x: 418, y: 96, width: 224, height: 200)] {
        panelColor.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 24, yRadius: 24).fill()
        NSColor.white.withAlphaComponent(0.10).setStroke()
        let border = NSBezierPath(roundedRect: rect, xRadius: 24, yRadius: 24)
        border.lineWidth = 1
        border.stroke()
    }

    NSColor.white.withAlphaComponent(0.72).setFill()
    for rect in [NSRect(x: 105, y: 108, width: 170, height: 36),
                 NSRect(x: 445, y: 108, width: 170, height: 36)] {
        NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12).fill()
    }

    let titleStyle: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 30, weight: .bold),
        .foregroundColor: NSColor.white,
        .kern: -0.6,
    ]
    let subtitleStyle: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 14, weight: .medium),
        .foregroundColor: NSColor.white.withAlphaComponent(0.68),
    ]
    let instructionStyle: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
        .foregroundColor: NSColor.white.withAlphaComponent(0.72),
        .kern: 1.6,
    ]

    NSString(string: "ContentCam").draw(at: NSPoint(x: 44, y: 362), withAttributes: titleStyle)
    NSString(string: "A private, native camera studio for your Mac")
        .draw(at: NSPoint(x: 46, y: 337), withAttributes: subtitleStyle)

    let instruction = NSString(string: "DRAG TO INSTALL")
    let instructionSize = instruction.size(withAttributes: instructionStyle)
    instruction.draw(at: NSPoint(x: (canvasSize.width - instructionSize.width) / 2, y: 313),
                     withAttributes: instructionStyle)

    let arrowColor = NSColor(red: 0.35, green: 0.72, blue: 1.0, alpha: 0.92)
    arrowColor.setStroke()
    arrowColor.setFill()
    let line = NSBezierPath()
    line.move(to: NSPoint(x: 318, y: 196))
    line.line(to: NSPoint(x: 395, y: 196))
    line.lineWidth = 5
    line.lineCapStyle = .round
    line.stroke()

    let arrowHead = NSBezierPath()
    arrowHead.move(to: NSPoint(x: 394, y: 207))
    arrowHead.line(to: NSPoint(x: 409, y: 196))
    arrowHead.line(to: NSPoint(x: 394, y: 185))
    arrowHead.close()
    arrowHead.fill()

    let footerStyle: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 12, weight: .regular),
        .foregroundColor: NSColor.white.withAlphaComponent(0.50),
    ]
    let footer = NSString(string: "Universal app  •  macOS 14 or newer  •  Camera processing stays on your Mac")
    let footerSize = footer.size(withAttributes: footerStyle)
    footer.draw(at: NSPoint(x: (canvasSize.width - footerSize.width) / 2, y: 42),
                withAttributes: footerStyle)

    return true
}

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to render the DMG background.\n", stderr)
    exit(1)
}

try png.write(to: outputURL)
