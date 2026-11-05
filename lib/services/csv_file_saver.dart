import 'dart:convert';
import 'package:file_picker/file_picker.dart';

/// The platform save step of CSV export: opens the system save dialog
/// pre-filled with [fileName] and writes [content]. Returns true when saved,
/// false when the user cancels. A seam so tests can stub it.
typedef CsvFileSaver = Future<bool> Function(String fileName, String content);

/// Default saver backed by the Android system save dialog (no permissions).
Future<bool> saveCsvFile(String fileName, String content) async {
  final uri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: utf8.encode(content),
    mimeType: 'text/csv',
  );
  return uri != null;
}
