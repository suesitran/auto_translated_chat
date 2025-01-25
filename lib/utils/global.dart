import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_stub.dart'
    if (dart.library.html) 'web_stub.dart'
    if (dart.library.io) 'non_web_stub.dart';

class Global {
  Global._internal();
  static final Global _instance = Global._internal();
  factory Global() => _instance;
  init() {
    localLanguageCode = getLanguageCode();
  }

  static String localLanguageCode = 'unknown';
  String getLanguageCode() {
    try {
      if (kIsWeb) {
        // Get language from web browser
        final browserLocale = getBrowserLanguage();
        return browserLocale.split('-')[0].toLowerCase();
      } else {
        // Get language from mobile device
        final deviceLocale = Platform.localeName;
        return deviceLocale.split('_')[0].toLowerCase();
      }
    } catch (e) {
      // Return 'unknown' as default language if there's an error
      return 'unknown';
    }
  }
}
