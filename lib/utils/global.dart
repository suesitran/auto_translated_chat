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
        // Lấy ngôn ngữ từ trình duyệt web
        final browserLocale = window.navigator.language;
        // ignore: unnecessary_null_comparison
        if (browserLocale == null) {
          return 'unknown';
        }
        return browserLocale.split('-')[0].toLowerCase();
      } else {
        // Lấy ngôn ngữ từ thiết bị mobile
        final deviceLocale = io.Platform.localeName; // Sử dụng 'dart:io' cho thiết bị di động
        return deviceLocale.split('_')[0].toLowerCase();
      }
    } catch (e) {
      // Trả về 'en' làm ngôn ngữ mặc định nếu có lỗi
      return 'unknown';
    }
  }
}
