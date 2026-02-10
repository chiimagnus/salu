import CoreGraphics
import RealityKit
import UIKit

@MainActor
enum FloatingTextFactory {
    enum Style: Sendable {
        case damage
        case block
        case neutral

        var textColor: UIColor {
            switch self {
            case .damage:
                return UIColor(red: 0.98, green: 0.28, blue: 0.24, alpha: 1.0)
            case .block:
                return UIColor(red: 0.26, green: 0.68, blue: 0.96, alpha: 1.0)
            case .neutral:
                return UIColor(white: 0.94, alpha: 1.0)
            }
        }

        var backgroundColor: UIColor {
            switch self {
            case .damage:
                return UIColor(red: 0.18, green: 0.05, blue: 0.04, alpha: 0.90)
            case .block:
                return UIColor(red: 0.04, green: 0.10, blue: 0.20, alpha: 0.90)
            case .neutral:
                return UIColor(white: 0.10, alpha: 0.88)
            }
        }
    }

    static func makeEntity(text: String, style: Style) -> ModelEntity? {
        guard let cgImage = renderLabel(text: text, style: style) else { return nil }
        do {
            let texture = try TextureResource(
                image: cgImage,
                withName: nil,
                options: .init(semantic: .color)
            )
            var material = UnlitMaterial()
            material.color = .init(tint: .white)
            material.color.texture = .init(texture)

            let entity = ModelEntity(mesh: .generatePlane(width: 0.18, height: 0.08), materials: [material])
            entity.name = "floatingText:\(text)"
            return entity
        } catch {
            return nil
        }
    }

    private static func renderLabel(text: String, style: Style) -> CGImage? {
        let size = CGSize(width: 512, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let bounds = CGRect(origin: .zero, size: size)

            UIColor.clear.setFill()
            ctx.fill(bounds)

            let bubbleRect = bounds.insetBy(dx: 16, dy: 30)
            let bubblePath = UIBezierPath(roundedRect: bubbleRect, cornerRadius: 28)
            style.backgroundColor.setFill()
            bubblePath.fill()

            UIColor(white: 1.0, alpha: 0.16).setStroke()
            bubblePath.lineWidth = 4
            bubblePath.stroke()

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center

            let font = UIFont.monospacedDigitSystemFont(ofSize: 92, weight: .heavy)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: style.textColor,
                .paragraphStyle: paragraph,
            ]
            let textRect = CGRect(
                x: bubbleRect.minX + 12,
                y: bubbleRect.minY + 30,
                width: bubbleRect.width - 24,
                height: bubbleRect.height - 40
            )
            (text as NSString).draw(in: textRect, withAttributes: attributes)
        }
        return image.cgImage
    }
}
