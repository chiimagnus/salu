import RealityKit

import GameCore

@MainActor
final class CardFaceTextureCache {
    struct Key: Hashable, Sendable {
        let cardIdRaw: String
        let displayModeRaw: String
        let languageRaw: String
    }

    private var textures: [Key: TextureResource] = [:]

    func texture(for cardId: CardID, displayMode: CardDisplayMode, language: GameLanguage) -> TextureResource? {
        let key = Key(cardIdRaw: cardId.rawValue, displayModeRaw: displayMode.rawValue, languageRaw: language.rawValue)
        if let cached = textures[key] {
            return cached
        }

        let def = CardRegistry.require(cardId)
        guard let cgImage = CardFaceRenderer.renderCGImage(def: def, displayMode: displayMode, language: language) else {
            return nil
        }

        do {
            let texture = try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
            textures[key] = texture
            return texture
        } catch {
            return nil
        }
    }

    func removeAll() {
        textures.removeAll(keepingCapacity: true)
    }
}

