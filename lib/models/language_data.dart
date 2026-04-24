// ─────────────────────────────────────────────────────────────────────────────
// FILE: lib/models/language_data.dart
// Single source of truth for all supported languages.
// ─────────────────────────────────────────────────────────────────────────────

class LanguageData {
  final String name;
  final String flag;
  final String nativeName;
  final String greeting;    // AI greeting hint
  final String colorHex;   // Card accent color

  const LanguageData({
    required this.name,
    required this.flag,
    required this.nativeName,
    required this.greeting,
    required this.colorHex,
  });
}

const List<LanguageData> kAvailableLanguages = [
  LanguageData(name: 'Spanish',    flag: '🇪🇸', nativeName: 'Español',    greeting: 'Hola',      colorHex: 'FF6B6B'),
  LanguageData(name: 'French',     flag: '🇫🇷', nativeName: 'Français',   greeting: 'Bonjour',   colorHex: '4ECDC4'),
  LanguageData(name: 'German',     flag: '🇩🇪', nativeName: 'Deutsch',    greeting: 'Hallo',     colorHex: 'FFE66D'),
  LanguageData(name: 'Japanese',   flag: '🇯🇵', nativeName: '日本語',      greeting: 'こんにちは', colorHex: 'FF8B94'),
  LanguageData(name: 'Korean',     flag: '🇰🇷', nativeName: '한국어',      greeting: '안녕하세요', colorHex: 'A8E6CF'),
  LanguageData(name: 'Mandarin',   flag: '🇨🇳', nativeName: '普通话',      greeting: '你好',       colorHex: 'F7DC6F'),
  LanguageData(name: 'Arabic',     flag: '🇸🇦', nativeName: 'العربية',    greeting: 'مرحباً',      colorHex: '82E0AA'),
  LanguageData(name: 'Italian',    flag: '🇮🇹', nativeName: 'Italiano',   greeting: 'Ciao',      colorHex: 'F0B27A'),
  LanguageData(name: 'English',    flag: '🇬🇧', nativeName: 'English',    greeting: 'Hello',     colorHex: '85C1E9'),
  LanguageData(name: 'Hindi',      flag: '🇮🇳', nativeName: 'हिन्दी',    greeting: 'नमस्ते',   colorHex: 'D2B4DE'),
  LanguageData(name: 'Bengali',    flag: '🇧🇩', nativeName: 'বাংলা',      greeting: 'হ্যালো',   colorHex: '76D7C4'),
  LanguageData(name: 'Russian',    flag: '🇷🇺', nativeName: 'Русский',    greeting: 'Привет',   colorHex: 'F1948A'),
];

/// Quick lookup by name
LanguageData? findLanguage(String name) {
  try {
    return kAvailableLanguages.firstWhere((l) => l.name == name);
  } catch (_) {
    return null;
  }
}