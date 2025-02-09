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
    String lang;
    try {
      if (kIsWeb) {
        // Lấy ngôn ngữ từ trình duyệt web
        lang = window.navigator.language;
      } else {
        // Lấy ngôn ngữ từ thiết bị mobile
        lang = io.Platform.localeName; // Sử dụng 'dart:io' cho thiết bị di động
      }
      return lang.split('_')[0].toLowerCase();
    } catch (e) {
      // Trả về 'en' làm ngôn ngữ mặc định nếu có lỗi
      return 'unknown';
    }
  }
}
