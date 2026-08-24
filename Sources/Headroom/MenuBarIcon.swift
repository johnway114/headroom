import AppKit

enum MenuBarIcon {
    static func make(remaining: Double? = nil) -> NSImage {
        let size = NSSize(width: 17, height: 17)
        let image = NSImage(size: size, flipped: true) { _ in
            NSColor.black.setFill()

            let x: CGFloat = 2.35
            let y: CGFloat = 1.7
            let width: CGFloat = 12.3
            let height: CGFloat = 13.5
            let stem: CGFloat = 3.05
            let radius: CGFloat = 1.45

            let lintel = NSRect(x: x, y: y, width: width, height: stem)
            let left = NSRect(x: x, y: y, width: stem, height: height)
            let right = NSRect(x: x + width - stem, y: y, width: stem, height: height)

            NSBezierPath(roundedRect: lintel, xRadius: radius, yRadius: radius).fill()
            NSBezierPath(roundedRect: left, xRadius: radius, yRadius: radius).fill()
            NSBezierPath(roundedRect: right, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
