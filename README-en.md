# 🔥  Salu the Fire

A cross-platform (macOS/Linux/Windows) turn-based card-battle game inspired by *Slay the Spire*, *Lord of the Mysteries*, and *Ender’s Game*.

## 📥  Download & Install

### Apple Vision Pro app (in development 🚧)

Open `SaluNative/SaluNative.xcodeproj` in Xcode and run `SaluAVP`.

Supported platforms:
- **visionOS** 26.0+ (in development 🚧)

### Command-Line Version (CLI)

> Requires Swift 6.2+, available from [swift.org](https://www.swift.org/install/)

```bash
# Clone the repository
git clone https://github.com/chiimagnus/salu.git
cd salu

# Run the game (random seed)
swift run
```

## 🤝  Contributing

Contributions are welcome! Please read the [repository contribution guide](AGENTS.md) before getting started.

This project is layered by architecture, and each module follows its own guidelines:

- `GameCore`: pure logic layer (rules/state/battle/cards/enemies/map/save snapshot models), see [GameCore guidelines](Sources/GameCore/AGENTS.md)
- `GameCLI`: CLI/TUI presentation layer (terminal rendering/input/room flow/persistence), see [GameCLI guidelines](Sources/GameCLI/AGENTS.md)
- `SaluNative/SaluAVP`: native app (visionOS, ImmersiveSpace + RealityKit), see `.github/plans/Plan AVP - Apple Vision Pro 原生 3D 实现（SaluAVP）.md`
