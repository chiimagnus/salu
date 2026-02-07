import CoreGraphics
import RealityKit
import UIKit

@MainActor
enum PileEntityFactory {
    static func makePileEntity(kind: PileKind, count: Int) -> ModelEntity {
        let body = ModelEntity(
            mesh: .generateBox(size: [0.06, 0.014, 0.08]),
            materials: [SimpleMaterial(color: UIColor(white: 0.15, alpha: 0.65), isMetallic: false)]
        )
        body.name = "pile:\(kind.rawValue)"
        body.components.set(CollisionComponent(shapes: [.generateBox(size: [0.07, 0.06, 0.09])]))
        body.components.set(InputTargetComponent())

        if let cg = renderLabelCGImage(title: kind.title, count: count) {
            do {
                let texture = try TextureResource.generate(from: cg, options: .init(semantic: .color))
                var labelMat = UnlitMaterial()
                labelMat.color = .init(tint: .white)
                labelMat.color.texture = .init(texture)

                let label = ModelEntity(mesh: .generatePlane(width: 0.058, height: 0.058), materials: [labelMat])
                label.name = "pileLabel"
                label.position = [0, 0.0086, 0]
                body.addChild(label)
            } catch {
                // ignore label failures; keep pile body visible
            }
        }

        return body
    }

    private static func renderLabelCGImage(title: String, count: Int) -> CGImage? {
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let bounds = CGRect(origin: .zero, size: size)

            UIColor(white: 1.0, alpha: 0.92).setFill()
            UIBezierPath(roundedRect: bounds.insetBy(dx: 10, dy: 10), cornerRadius: 24).fill()

            UIColor(white: 0.0, alpha: 0.18).setStroke()
            let border = UIBezierPath(roundedRect: bounds.insetBy(dx: 10, dy: 10), cornerRadius: 24)
            border.lineWidth = 6
            border.stroke()

            let titleFont = UIFont.systemFont(ofSize: 40, weight: .bold)
            let countFont = UIFont.monospacedDigitSystemFont(ofSize: 64, weight: .heavy)

            let para = NSMutableParagraphStyle()
            para.alignment = .center

            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor(white: 0.12, alpha: 1.0),
                .paragraphStyle: para,
            ]
            let countAttr: [NSAttributedString.Key: Any] = [
                .font: countFont,
                .foregroundColor: UIColor(white: 0.10, alpha: 1.0),
                .paragraphStyle: para,
            ]

            let titleRect = CGRect(x: 16, y: 24, width: bounds.width - 32, height: 60)
            (title as NSString).draw(in: titleRect, withAttributes: titleAttr)

            let countRect = CGRect(x: 16, y: 92, width: bounds.width - 32, height: 120)
            ("\(count)" as NSString).draw(in: countRect, withAttributes: countAttr)
        }
        return image.cgImage
    }
}

