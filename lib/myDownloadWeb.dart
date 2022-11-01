import 'dart:convert';
import 'dart:html' as html;

Future<void> download(String fileName, List<int> bytes) async{
  html.AnchorElement(
      href:
      "data:application/octet-stream;charset=utf-16le;base64,${base64.encode(bytes)}")
    ..setAttribute("download", fileName)
    ..click();
}