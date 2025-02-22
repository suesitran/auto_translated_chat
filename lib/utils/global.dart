import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:universal_html/html.dart';

class Global {
  Global._internal();
  static final Global _instance = Global._internal();
  factory Global() => _instance;
  init() {
    localLanguageCode = getLanguageCode();
    if (kDebugMode) {
      print('localLanguageCode: $localLanguageCode');
    }
  }

  static String localLanguageCode = 'unknown';
  String getLanguageCode() {
    try {
      if (kIsWeb) {
        // Get language from web browser
        final browserLocale = window.navigator.language;
        // ignore: unnecessary_null_comparison
        if (browserLocale == null) {
          // fix Error: Method 'split' cannot be called on 'String?' because it is potentially null.
          return 'unknown';
        }
        return browserLocale.split('-')[0].toLowerCase();
      } else {
        // Get language from mobile device
        final deviceLocale =
            io.Platform.localeName; // Use 'dart:io' for mobile devices
        return deviceLocale.split('_')[0].toLowerCase();
      }
    } catch (e) {
      // Return 'en' as default language if there's an error
      return 'unknown';
    }
  }
}
