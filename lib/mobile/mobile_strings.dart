import '../l10n/app_language.dart';

String mobileText(String en, String ko, String ja) =>
    switch (AppLanguage.instance.code) {
      'ko' => ko,
      'ja' => ja,
      _ => en,
    };
