# 🌙 Zakat Calculator

A premium, comprehensive Islamic Zakat calculator built with Flutter. This app follows the **Hanafi school of jurisprudence** and incorporates the spiritual essence of Islamic teachings with a modern, high-end user experience.

![App Header](assets/images/header.png) *Note: Add your app screenshot here*

## ✨ Premium Features

### 🕌 Religious Excellence
- **Bismillah Startup**: A beautiful, dedicated loading screen featuring "**بِسْمِ ٱللَّٰهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ**" on a premium teal background.
- **Quran & Hadith Integration**: The home screen features inspiring verses (Quran 2:43) and Sahih Hadith (Narrated by Ibn Umar) regarding the importance of Zakat.
- **Hanafi Standard**: Strictly follows calculations based on 595 grams of silver (Nisab).

### 🌍 Global & Intelligent
- **Auto Currency Detection**: Leverages GPS to automatically detect your country and set the local currency (INR, USD, CAD, SAR, AED, etc.).
- **Real-Time Market Rates**: Fetches live gold and silver prices with purity adjustments (24K, 22K, 18K, 14K).
- **Multi-Language Support**: Fully localized in English, Urdu (اردو), Arabic (العربية), and Hindi (हिन्दी).

### 🎨 High-End UI/UX
- **Separated Rate Cards**: Clean, organized dashboard with distinct sections for Gold and Silver rates.
- **Standardized Currency**: Uses international currency codes (e.g., 10,000 INR) for professional clarity.
- **Material 3 Design**: Modern, responsive, and supports **Dynamic Dark Mode**.

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.2.0+)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code

### 2. Installation
```bash
# Clone the repository
git clone https://github.com/yourusername/zakat_calculator.git

# Navigate to project
cd zakat_calculator

# Get dependencies
flutter pub get

# Run the app
flutter run
```

---

## 🌐 Deployment to Vercel (Flutter Web)

The app is fully compatible with Flutter Web. To deploy to Vercel:

1. **Enable Web**:
   ```bash
   flutter config --enable-web
   ```
2. **Build for Web**:
   ```bash
   flutter build web --release
   ```
3. **Deploy**:
   - Install Vercel CLI: `npm i -g vercel`
   - Run `vercel` in the project root.
   - When asked for the output directory, specify `build/web`.

*Alternatively, push to GitHub and connect your repo to Vercel. Use `flutter build web --release` as the build command.*

---

## 🏗️ Project Architecture

```
lib/
├── models/      # Zakat & Metal Rate data structures
├── providers/   # State Management (AppProvider)
├── screens/     # UI Pages (Home, Calculator, etc.)
├── services/    # Logic (Location, Rates, Storage)
└── widgets/     # Reusable components (Bismillah Splash)
```

## 🔐 Privacy
- **100% Offline-First**: No financial data ever leaves your device. Everything is stored in local persistent storage.
- **Open Source**: Transparent calculation logic as per Shariah.

## 👨‍💻 Developer
**Amaanullah Sayyed**  
*Software Engineer*  
Version: 1.0.1  

---

**Barakallahu Feekum** (May Allah bless you)
Made with ❤️ for the Muslim Ummah
