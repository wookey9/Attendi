import 'dart:io';
import 'package:open_file_safe/open_file_safe.dart';
import 'package:path_provider/path_provider.dart';

Future<void> download(String fileName, List<int> bytes) async{
  final directory = await getApplicationDocumentsDirectory();
  File file = File(directory.path +'/'+fileName);
  file.writeAsBytes(bytes).then((value) {
    OpenFile.open(value.path);
  });
}