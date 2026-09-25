/// A language to recognize: a whisper code and the language's own name.
typedef CaptionLanguage = ({String code, String name});

/// Languages offered for captions, besides detecting it. Each is named in
/// itself, so the list reads the same in any app language. Ordered by
/// English name.
const captionLanguages = <CaptionLanguage>[
  (code: 'am', name: 'አማርኛ'),
  (code: 'ar', name: 'العربية'),
  (code: 'bn', name: 'বাংলা'),
  (code: 'zh', name: '中文'),
  (code: 'cs', name: 'Čeština'),
  (code: 'da', name: 'Dansk'),
  (code: 'nl', name: 'Nederlands'),
  (code: 'en', name: 'English'),
  (code: 'fi', name: 'Suomi'),
  (code: 'fr', name: 'Français'),
  (code: 'de', name: 'Deutsch'),
  (code: 'el', name: 'Ελληνικά'),
  (code: 'ha', name: 'Hausa'),
  (code: 'he', name: 'עברית'),
  (code: 'hi', name: 'हिन्दी'),
  (code: 'hu', name: 'Magyar'),
  (code: 'id', name: 'Bahasa Indonesia'),
  (code: 'it', name: 'Italiano'),
  (code: 'ja', name: '日本語'),
  (code: 'ko', name: '한국어'),
  (code: 'ms', name: 'Bahasa Melayu'),
  (code: 'mr', name: 'मराठी'),
  (code: 'no', name: 'Norsk'),
  (code: 'fa', name: 'فارسی'),
  (code: 'pl', name: 'Polski'),
  (code: 'pt', name: 'Português'),
  (code: 'ro', name: 'Română'),
  (code: 'ru', name: 'Русский'),
  (code: 'es', name: 'Español'),
  (code: 'sw', name: 'Kiswahili'),
  (code: 'sv', name: 'Svenska'),
  (code: 'tl', name: 'Tagalog'),
  (code: 'ta', name: 'தமிழ்'),
  (code: 'te', name: 'తెలుగు'),
  (code: 'th', name: 'ไทย'),
  (code: 'tr', name: 'Türkçe'),
  (code: 'uk', name: 'Українська'),
  (code: 'ur', name: 'اردو'),
  (code: 'vi', name: 'Tiếng Việt'),
  (code: 'yo', name: 'Yorùbá'),
];

/// The name of [code], or null when it is not offered.
String? captionLanguageName(String? code) {
  for (final l in captionLanguages) {
    if (l.code == code) return l.name;
  }
  return null;
}
