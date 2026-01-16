import GameCore

extension Entity {
    init(id: String, name: String, maxHP: Int, enemyId: EnemyID? = nil) {
        let localizedName = LocalizedText(name, name)
        if let enemyId {
            self.init(id: id, name: localizedName, maxHP: maxHP, enemyId: enemyId)
        } else {
            self.init(id: id, name: localizedName, maxHP: maxHP)
        }
    }
}
