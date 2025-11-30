import 'package:translator/translator.dart';

class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();

  /// Translates text from English to Vietnamese
  Future<String> translateToVietnamese(String text) async {
    try {
      if (text.isEmpty) return text;

      final translation = await _translator.translate(
        text,
        from: 'en',
        to: 'vi',
      );

      return translation.text;
    } catch (e) {
      // Return original text if translation fails
      return text;
    }
  }

  /// Translates a list of strings from English to Vietnamese
  Future<List<String>> translateListToVietnamese(List<String> texts) async {
    try {
      final List<String> translations = [];

      for (String text in texts) {
        final translated = await translateToVietnamese(text);
        translations.add(translated);
      }

      return translations;
    } catch (e) {
      // Return original texts if translation fails
      return texts;
    }
  }
}
