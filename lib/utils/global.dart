// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'web_stub.dart' if (dart.library.html) 'web_browser.dart';

class Global {
  Global._internal();
  static final Global _instance = Global._internal();
  factory Global() => _instance;

  // final BrowserUtil _browserUtil = BrowserUtil();

  init() {
    localLanguageCode = getLanguageCode();
  }

  static String localLanguageCode = 'unknown';
  String getLanguageCode() {
    return 'vi';
    // try {
    //   if (kIsWeb) {
    //     // Get language from web browser
    //     final browserLocale = _browserUtil.getBrowserLanguage();
    //     return browserLocale.split('-')[0].toLowerCase();
    //   } else {
    //     // Get language from mobile device
    //     final deviceLocale = Platform.localeName;
    //     return deviceLocale.split('_')[0].toLowerCase();
    //   }
    // } catch (e) {
    //   // Return 'unknown' as default language if there's an error
    //   return 'unknown';
    // }
  }
}
