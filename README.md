# 🎴 iUnus

> The classic UNO card game, natively reimagined for iOS with SwiftUI.

[Report Bug](https://github.com/VidiPT89/iUnus/issues) · [Request Feature](https://github.com/VidiPT89/iUnus/issues)

## ✨ Features

- ✅ Full original UNO rules — 108-card deck, 1 to 4 players, Skip/Reverse/Draw Two/Wild/Wild Draw Four
- ✅ Smart AI opponents with strategic card and color selection
- ✅ Smooth, native SwiftUI animations — card dealing, playing, and draw-pile motion
- ✅ Haptic feedback on key moments (playing a card, invalid moves, UNO calls, wins)
- ✅ "UNO!" call mechanic with a timed penalty if you get caught
- ✅ Multi-round scoring up to 500 points, with round and game summary screens
- ✅ Runtime language switch — Português (PT-PT) and English, independent of system locale
- ✅ Dark mode, Light mode, and System mode
- ✅ Custom color identity inspired by [ividi.dev](https://ividi.dev/) — burnt orange, amber and black

## 🛠️ Tech Stack

| Category    | Technology            |
|-------------|------------------------|
| Language    | Swift 5.9+              |
| UI          | SwiftUI (iOS 16+)        |
| Architecture| MVVM                     |
| Project     | XcodeGen                 |

## 🚀 Quick Start

**Prerequisites**
- Xcode 15+
- iOS 16+ simulator or device

**Steps**

```bash
git clone https://github.com/VidiPT89/iUnus.git
cd iUnus
open iUnus.xcodeproj
```

Select the `iUnus` scheme and run on a simulator or device.

## 📖 Usage

Launch the app, choose the number of opponents from the main menu, and play a full game of UNO
against the built-in AI. Tap the language and appearance icons in Settings to switch between
PT-PT/English and Light/Dark/System mode at any time.

## 🧪 Testing

Build and run the `iUnus` scheme in Xcode (`⌘R`), or verify the project compiles via:

```bash
xcodebuild -project iUnus.xcodeproj -scheme iUnus -destination 'generic/platform=iOS Simulator' build
```

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

## 👨‍💻 Author

**David Arsénio Martins**

🌐 Website: [ividi.dev](https://ividi.dev/)
🐙 GitHub: [@VidiPT89](https://github.com/VidiPT89/)

## 🤝 Contributing

Contributions, issues and feature requests are welcome. Feel free to check the [issues page](https://github.com/VidiPT89/iUnus/issues).

---

<p align="center">Developed by <a href="https://ividi.dev">David Arsénio Martins</a></p>
<p align="center">If you like this project, consider giving it a ⭐</p>
