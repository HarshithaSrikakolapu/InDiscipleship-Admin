// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:convert';

class WebDownloadHelper {
  static void downloadStringAsFile(String content, String fileName) {
    final bytes = utf8.encode(content);
    final blob = web.Blob([bytes.toJS].toJS);
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    web.document.body?.appendChild(anchor);

    anchor.click();

    web.document.body?.removeChild(anchor);
    web.URL.revokeObjectURL(url);
  }
}
