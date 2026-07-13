// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

class WebDownloadHelper {
  static void downloadStringAsFile(String content,  String fileName) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    html.document.body?.children.add(anchor);
    
    anchor.click();
    
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
