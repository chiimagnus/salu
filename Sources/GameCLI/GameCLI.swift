import GameCore

@main
struct GameCLI {
    static func main() {
        // P1 验证：测试 GameCore 模块是否正确导入
        let deck = createStarterDeck()
        print("Salu - Slay the Spire CLI")
        print("初始牌组：\(deck.count) 张")
        
        // 测试 RNG
        let rng = SeededRNG(seed: 1)
        var testArray = [1, 2, 3, 4, 5]
        rng.shuffle(&testArray)
        print("RNG 测试洗牌：\(testArray)")
    }
}
