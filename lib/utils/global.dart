import 'dart:io';
import 'dart:html' if (dart.library.html) 'dart:html' show window;
import 'package:flutter/foundation.dart' show kIsWeb;

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
        // Lấy ngôn ngữ từ trình duyệt web
        final browserLocale = window.navigator.language;
        return browserLocale.split('-')[0].toLowerCase();
      } else {
        // Lấy ngôn ngữ từ thiết bị mobile
        final deviceLocale = Platform.localeName;
        return deviceLocale.split('_')[0].toLowerCase();
      }
    } catch (e) {
      // Trả về 'en' làm ngôn ngữ mặc định nếu có lỗi
      return 'unknown';
    }
  }
}
