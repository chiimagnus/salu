import CoreGraphics
import UIKit

import GameCore

@MainActor
enum CardFaceRenderer {
    static func renderCGImage(
        def: any CardDefinition.Type,
        displayMode: CardDisplayMode,
        language: GameLanguage,
        size: CGSize = CGSize(width: 512, height: 768)
    ) -> CGImage? {
        let name = def.name.resolved(for: language)
        let type = def.type.displayName(language: language)
        let rulesText = def.rulesText.resolved(for: language)
        let costText = "\(def.cost)"

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let bounds = CGRect(origin: .zero, size: size)

            UIColor(white: 0.98, alpha: 1.0).setFill()
            ctx.fill(bounds)

            let cardRect = bounds.insetBy(dx: 14, dy: 14)
            let cornerRadius: CGFloat = 28
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: cornerRadius)
            UIColor(white: 1.0, alpha: 1.0).setFill()
            cardPath.fill()

            UIColor(white: 0.0, alpha: 0.12).setStroke()
            cardPath.lineWidth = 4
            cardPath.stroke()

            // Header stripe
            let headerHeight: CGFloat = 108
            let headerRect = CGRect(x: cardRect.minX, y: cardRect.minY, width: cardRect.width, height: headerHeight)
            let headerPath = UIBezierPath(
                roundedRect: headerRect,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            )
            headerColor(for: def.type).setFill()
            headerPath.fill()

            // Cost bubble
            if displayMode != .modeA {
                let costDiameter: CGFloat = 72
                let costRect = CGRect(
                    x: cardRect.minX + 16,
                    y: cardRect.minY + 16,
                    width: costDiameter,
                    height: costDiameter
                )
                let bubblePath = UIBezierPath(ovalIn: costRect)
                UIColor(white: 1.0, alpha: 0.92).setFill()
                bubblePath.fill()
                UIColor(white: 0.0, alpha: 0.18).setStroke()
                bubblePath.lineWidth = 3
                bubblePath.stroke()

                let costFont = UIFont.systemFont(ofSize: 40, weight: .bold)
                let costAttr: [NSAttributedString.Key: Any] = [
                    .font: costFont,
                    .foregroundColor: UIColor(white: 0.05, alpha: 1.0),
                ]
                let costSize = (costText as NSString).size(withAttributes: costAttr)
                let costPoint = CGPoint(
                    x: costRect.midX - costSize.width / 2,
                    y: costRect.midY - costSize.height / 2
                )
                (costText as NSString).draw(at: costPoint, withAttributes: costAttr)
            }

            // Title
            let titleFont = UIFont.systemFont(ofSize: 44, weight: .heavy)
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor(white: 1.0, alpha: 0.98),
            ]
            let titleRect = CGRect(
                x: cardRect.minX + 112,
                y: cardRect.minY + 26,
                width: cardRect.width - 128,
                height: 70
            )
            drawText(name, in: titleRect, attributes: titleAttr, lineBreakMode: .byTruncatingTail, maxLines: 1)

            // Body
            let bodyInset: CGFloat = 24
            let bodyRect = CGRect(
                x: cardRect.minX + bodyInset,
                y: cardRect.minY + headerHeight + 14,
                width: cardRect.width - bodyInset * 2,
                height: cardRect.height - headerHeight - 28
            )

            if displayMode == .modeA {
                let centerRect = CGRect(x: bodyRect.minX, y: bodyRect.minY + 120, width: bodyRect.width, height: 160)
                let centerFont = UIFont.systemFont(ofSize: 56, weight: .bold)
                let centerStyle = NSMutableParagraphStyle()
                centerStyle.alignment = .center
                let centerAttr: [NSAttributedString.Key: Any] = [
                    .font: centerFont,
                    .foregroundColor: UIColor(white: 0.12, alpha: 1.0),
                    .paragraphStyle: centerStyle,
                ]
                drawText(name, in: centerRect, attributes: centerAttr, lineBreakMode: .byTruncatingTail, maxLines: 2)
                return
            }

            if displayMode == .modeC || displayMode == .modeD {
                let typeFont = UIFont.systemFont(ofSize: 24, weight: .semibold)
                let typeStyle = NSMutableParagraphStyle()
                typeStyle.alignment = .left
                let typeAttr: [NSAttributedString.Key: Any] = [
                    .font: typeFont,
                    .foregroundColor: UIColor(white: 0.18, alpha: 1.0),
                    .paragraphStyle: typeStyle,
                ]
                let typeRect = CGRect(x: bodyRect.minX, y: bodyRect.minY, width: bodyRect.width, height: 30)
                drawText(type, in: typeRect, attributes: typeAttr, lineBreakMode: .byTruncatingTail, maxLines: 1)
            }

            let textFont = UIFont.systemFont(ofSize: 28, weight: .regular)
            let para = NSMutableParagraphStyle()
            para.alignment = .left
            para.lineBreakMode = (displayMode == .modeD) ? .byWordWrapping : .byTruncatingTail
            para.lineSpacing = 6

            let textAttr: [NSAttributedString.Key: Any] = [
                .font: textFont,
                .foregroundColor: UIColor(white: 0.12, alpha: 1.0),
                .paragraphStyle: para,
            ]

            let textTop: CGFloat = (displayMode == .modeB) ? 0 : 42
            let rulesRect = CGRect(
                x: bodyRect.minX,
                y: bodyRect.minY + textTop,
                width: bodyRect.width,
                height: bodyRect.height - textTop
            )

            switch displayMode {
            case .modeA:
                break
            case .modeB:
                let bodyStyle = NSMutableParagraphStyle()
                bodyStyle.alignment = .center
                let bodyAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 34, weight: .semibold),
                    .foregroundColor: UIColor(white: 0.12, alpha: 1.0),
                    .paragraphStyle: bodyStyle,
                ]
                drawText(name, in: rulesRect, attributes: bodyAttr, lineBreakMode: .byTruncatingTail, maxLines: 3)
            case .modeC:
                drawText(rulesText, in: rulesRect, attributes: textAttr, lineBreakMode: .byTruncatingTail, maxLines: 2)
            case .modeD:
                drawText(rulesText, in: rulesRect, attributes: textAttr, lineBreakMode: .byWordWrapping, maxLines: nil)
            }
        }

        return image.cgImage
    }

    private static func headerColor(for type: CardType) -> UIColor {
        switch type {
        case .attack:
            return UIColor.systemRed.withAlphaComponent(0.86)
        case .skill:
            return UIColor.systemBlue.withAlphaComponent(0.86)
        case .power:
            return UIColor.systemPurple.withAlphaComponent(0.86)
        case .consumable:
            return UIColor.systemGreen.withAlphaComponent(0.86)
        }
    }

    private static func drawText(
        _ text: String,
        in rect: CGRect,
        attributes: [NSAttributedString.Key: Any],
        lineBreakMode: NSLineBreakMode,
        maxLines: Int?
    ) {
        let paragraph = (attributes[.paragraphStyle] as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
        paragraph.lineBreakMode = lineBreakMode

        var attrs = attributes
        attrs[.paragraphStyle] = paragraph

        let attributed = NSMutableAttributedString(string: text, attributes: attrs)

        if let maxLines {
            // Approximate: limit height by lineHeight * maxLines. UIKit doesn't support "max lines" directly
            // in draw(with:) so we constrain the rect height.
            let font = (attributes[.font] as? UIFont) ?? UIFont.systemFont(ofSize: 14)
            let lineHeight = font.lineHeight + paragraph.lineSpacing
            let maxHeight = ceil(CGFloat(maxLines) * lineHeight)
            let limited = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: min(rect.height, maxHeight))
            attributed.draw(with: limited, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        } else {
            attributed.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        }
    }
}

