# 🌙 Zakat Calculator

A comprehensive Islamic Zakat calculator built with Flutter, following the **Hanafi school of jurisprudence**. Features real-time gold & silver rates, city-level rate adjustments for India, automatic location detection, and full offline support.

---

## ✨ Features

### 🕌 Islamic Excellence
- **Hanafi Standard**: Nisab calculated on 595 grams of silver (more conservative, widely used)
- **Gold Nisab Display**: Shows value of 87.5g gold nisab at current market rate
- **Quran & Hadith**: Home screen features Quran 2:43 and Bukhari Hadith on Zakat
- **Bismillah Splash**: Dedicated startup screen with full Arabic Basmala

### 📈 Real-Time Market Rates
- **Auto-update on startup**: Rates refresh automatically in the background when online
- **Live gold & silver rates** via [gold-api.com](https://gold-api.com) — Free, no key required, no rate limits
- **Real-time currency conversion** via [exchangerate-api.com](https://api.exchangerate-api.com) — USD → any local currency
- **Purity breakdowns**: 24K, 22K, 18K, 14K gold + 99.9% silver
- **Offline fallback**: Accurate rates (updated March 2026) used when no internet

### 🌍 Global & Location-Aware
- **Auto-detect location**: GPS-based location detection sets currency automatically (INR, USD, AED, SAR, GBP, PKR, and 15+ currencies)
- **City search**: Search any city worldwide via OpenStreetMap Nominatim
- **India city-wise rates**: Gold prices vary 0.5–1.5% across Indian cities due to state taxes — Mumbai, Delhi, Chennai, Kolkata, Hyderabad, Bangalore, Kochi, and 40+ cities supported
- **Country-level rates**: Correct local currency for 25+ countries worldwide

### 🌐 Multi-Language
- English, اردو, العربية, हिन्दी

### 🎨 Premium UI/UX
- Material 3 Design with Dynamic Dark Mode
- Separated Gold / Silver rate cards with purity breakdown
- City-specific rate indicator on home screen

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.2.0

### Installation
```bash
git clone https://github.com/sayyedscholar/zakat_calculator.git
cd zakat_calculator
flutter pub get
flutter run
```

---

## 🌐 Web Deployment (Vercel)

```bash
# Build locally
flutter build web --release --base-href /

# Deploy via Vercel CLI
npm i -g vercel
cd build/web
vercel --prod
```

---

## 🏗️ Architecture

```
lib/
├── models/
│   ├── metal_rates.dart         # Gold/silver rate model with location field
│   └── zakat_calculation.dart   # Zakat calculation data model
├── providers/
│   └── app_provider.dart        # State management, auto-update, location
├── screens/
│   ├── home_screen.dart         # Dashboard with live rates + location display
│   ├── calculator_screen.dart   # Zakat calculator form
│   ├── settings_screen.dart     # Language, theme, data settings
│   └── about_screen.dart        # App info and Islamic references
├── services/
│   ├── rates_service.dart       # Live rate fetching, city adjustment, offline cache
│   ├── location_service.dart    # GPS, geocoding, city search
│   ├── storage_service.dart     # SharedPreferences persistence
│   └── localization_service.dart # Multi-language support
└── widgets/
    └── bismillah_splash.dart    # Startup splash screen
```

### Rate Fetching Strategy
1. **Primary**: `gold-api.com` → Real-time XAU/XAG price in USD (free, no key, no limits)
2. **Currency conversion**: `exchangerate-api.com` → USD to local currency (free, ~1500 req/month)
3. **India city adjustment**: Static factor map for 40+ Indian cities based on local state taxes
4. **Offline fallback**: Pre-loaded accurate rates (March 2026 — INR gold ₹16,100/gram, silver ₹290/gram) stored locally

---

## 🔐 Privacy

- All financial data stored **locally only** via SharedPreferences
- No personal data transmitted — only public market data APIs are called
- Open source calculation logic as per Shariah

---

## 👨‍💻 Developer

**Amaanullah Sayyed** — Software Engineer  
Version: 1.1.0

---

**بَارَكَ اللّهُ فِيكَ** — Barakallahu Feekum  
Made with ❤️ for the Muslim Ummah
