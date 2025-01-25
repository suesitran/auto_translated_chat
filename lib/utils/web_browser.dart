import 'package:universal_html/html.dart' as html;
import 'browser_interface.dart';

class BrowserUtil implements BrowserInterface {
  @override
  String getBrowserLanguage() {
    try {
      return html.window.navigator.language;
    } catch (_) {
      return 'unknown';
    }
  }
}
