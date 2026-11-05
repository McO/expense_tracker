import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

/// The platform file-picking step of CSV import: returns the chosen file's
/// text, or null when the user cancels. A seam so tests can stub it.
typedef CsvFilePicker = Future<String?> Function();

/// Default picker backed by the system file chooser.
Future<String?> pickCsvFileText() async {
  final file = await FilePicker.pickFile(type: FileType.any);
  if (file == null) return null;
  final path = file.path;
  if (path == null) return null;
  final bytes = await File(path).readAsBytes();
  return utf8.decode(bytes, allowMalformed: true);
}
