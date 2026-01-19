# 🔥  Salu the Fire

A cross-platform (macOS/Linux/Windows) turn-based card-battle game inspired by *Slay the Spire*, *Lord of the Mysteries*, and *Ender’s Game*.

## 📥  Download & Install

### Option 1: Native App (in development 🚧)

Open `SaluNative/SaluNative.xcodeproj` in Xcode and run `SaluCRH`.

Supported platforms:
- **macOS** 14+ (supported ✅)
- **visionOS** 2+ (in progress ⏳)

> Requirements: Xcode 16+ / macOS 14+

### Option 2: Command-Line Version (CLI)

> Requires Swift 6.2+, available from [swift.org](https://www.swift.org/install/)

```bash
# Clone the repository
git clone https://github.com/chiimagnus/salu.git
cd salu

# Run the game (random seed)
swift run
```

### Option 3: Direct Download

Download the latest release from the [Releases](https://github.com/chiimagnus/salu/releases) page:

| Platform | Package |
|------|----------|
| **macOS** | `salu-macos.tar.gz` |
| **Linux** | `salu-linux-x86_64.tar.gz` |
| **Windows** | `salu-windows-x86_64.zip` |

#### macOS / Linux usage

```bash
# Extract (macOS example)
tar -xzf salu-macos.tar.gz

# Run
./salu-macos
```

#### Windows usage

1. Extract `salu-windows-x86_64.zip`
2. Double-click `salu-windows-x86_64.exe` or run it in Command Prompt

## 🤝  Contributing

Contributions are welcome! Please read the [repository contribution guide](AGENTS.md) before getting started.

This project is layered by architecture, and each module follows its own guidelines:

- `GameCore`: pure logic layer (rules/state/battle/cards/enemies/map/save snapshot models), see [GameCore guidelines](Sources/GameCore/AGENTS.md)
- `GameCLI`: CLI/TUI presentation layer (terminal rendering/input/room flow/persistence), see [GameCLI guidelines](Sources/GameCLI/AGENTS.md)
- `SaluNative/SaluCRH`: native app (Multiplatform SwiftUI + SwiftData, macOS/visionOS), see [SaluCRH guidelines](SaluNative/SaluCRH/AGENTS.md)
