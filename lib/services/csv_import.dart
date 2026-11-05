import 'dart:convert';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import 'transactions_store.dart';

/// Header of the app's own CSV export (ADR-0005); the only accepted format.
const String csvExportHeader = 'Date,Title,Category,Amount,Currency,Description';

/// One rejected row of an import file, with its 1-based line number.
class ImportRowError {
  final int line;
  final String message;
  const ImportRowError(this.line, this.message);

  @override
  String toString() => 'Line $line: $message';
}

/// The outcome of reading a CSV file against a target account, before
/// anything is written. [fileError] set means the whole file is rejected.
class ImportPreview {
  final String? fileError;
  final List<Transaction> toImport;
  final int duplicates;
  final int mappedToOther;
  final List<ImportRowError> invalid;

  const ImportPreview({
    this.fileError,
    this.toImport = const [],
    this.duplicates = 0,
    this.mappedToOther = 0,
    this.invalid = const [],
  });

  bool get hasNothingToImport => fileError != null || toImport.isEmpty;
}

/// Splits CSV text into records of fields, honouring quoted fields with
/// commas, doubled quotes and newlines. Each record carries the 1-based line
/// number it starts on.
List<({int line, List<String> fields})> parseCsvRecords(String text) {
  if (text.startsWith('﻿')) text = text.substring(1);
  final records = <({int line, List<String> fields})>[];
  var fields = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var line = 1;
  var recordLine = 1;
  var hasContent = false;

  void endRecord() {
    fields.add(field.toString());
    field.clear();
    final blank = fields.length == 1 && fields.first.isEmpty && !hasContent;
    if (!blank) records.add((line: recordLine, fields: fields));
    fields = <String>[];
    hasContent = false;
  }

  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        if (c == '\n') line++;
        field.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
      hasContent = true;
    } else if (c == ',') {
      fields.add(field.toString());
      field.clear();
      hasContent = true;
    } else if (c == '\r') {
      // swallowed; the following \n ends the record
      if (i + 1 >= text.length || text[i + 1] != '\n') {
        endRecord();
        line++;
        recordLine = line;
      }
    } else if (c == '\n') {
      endRecord();
      line++;
      recordLine = line;
    } else {
      field.write(c);
      hasContent = true;
    }
  }
  if (hasContent || field.isNotEmpty || fields.isNotEmpty) endRecord();
  return records;
}

String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

String _rowKey(DateTime date, double signedAmount, String title, String categoryId) =>
    '${_dayKey(date)}|${signedAmount.toStringAsFixed(2)}|$title|$categoryId';

DateTime? _parseDate(String s) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s.trim());
  if (m == null) return null;
  final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), d = int.parse(m.group(3)!);
  final date = DateTime(y, mo, d, 12);
  if (date.year != y || date.month != mo || date.day != d) return null;
  return date;
}

/// Picks the category for an exported name: effective export name first, then
/// name, case-insensitively. Returns null when unknown.
Category? matchCategory(String name, List<Category> categories) {
  final n = name.trim().toLowerCase();
  if (n.isEmpty) return null;
  for (final c in categories) {
    if (c.effectiveExportName.trim().toLowerCase() == n) return c;
  }
  for (final c in categories) {
    if (c.name.trim().toLowerCase() == n) return c;
  }
  return null;
}

/// Reads [csv] (the app's own export) into transactions for [account]; pure,
/// writes nothing. [existing] are the transactions already in the account.
ImportPreview buildImportPreview({
  required String csv,
  required Account account,
  required List<Category> categories,
  required List<Transaction> existing,
  String Function()? idGenerator,
}) {
  final records = parseCsvRecords(csv);
  if (records.isEmpty ||
      records.first.fields.map((f) => f.trim()).join(',') != csvExportHeader) {
    return const ImportPreview(
        fileError: 'Not a file this app exported: expected the header '
            '"$csvExportHeader".');
  }

  final other = categories.firstWhere((c) => c.id == 'other',
      orElse: () => Category.defaultCategories.last);
  final existingKeys = {
    for (final t in existing.where((t) => t.accountId == account.id))
      _rowKey(t.date, t.signedAmount, t.title, t.category.id)
  };

  var seq = 0;
  final base = DateTime.now().microsecondsSinceEpoch;
  String nextId() => idGenerator != null ? idGenerator() : '${base + seq++}';

  final toImport = <Transaction>[];
  final invalid = <ImportRowError>[];
  var duplicates = 0;
  var mappedToOther = 0;

  for (final r in records.skip(1)) {
    final f = r.fields;
    if (f.length != 6) {
      invalid.add(ImportRowError(r.line, 'expected 6 columns but found ${f.length}'));
      continue;
    }
    final currency = f[4].trim();
    if (currency.toUpperCase() != account.currency.code.toUpperCase()) {
      return ImportPreview(
          fileError: 'Currency mismatch on line ${r.line}: the file has '
              '"$currency" but account "${account.name}" uses ${account.currency.code}. '
              'Nothing was imported.');
    }
    final date = _parseDate(f[0]);
    if (date == null) {
      invalid.add(ImportRowError(r.line, 'invalid date "${f[0]}" (expected yyyy-MM-dd)'));
      continue;
    }
    final amount = double.tryParse(f[3].trim());
    if (amount == null || amount.isNaN || amount.isInfinite) {
      invalid.add(ImportRowError(r.line, 'amount "${f[3]}" is not a number'));
      continue;
    }
    if (amount == 0) {
      invalid.add(ImportRowError(r.line, 'amount must not be zero'));
      continue;
    }
    final matched = matchCategory(f[2], categories);
    final category = matched ?? other;
    final signed = double.parse(amount.toStringAsFixed(2));
    if (existingKeys.contains(_rowKey(date, signed, f[1], category.id))) {
      duplicates++;
      continue;
    }
    if (matched == null) mappedToOther++;
    toImport.add(Transaction(
      id: nextId(),
      title: f[1],
      amount: amount.abs(),
      currency: account.currency,
      category: category,
      date: date,
      description: f[5],
      type: amount > 0 ? TransactionType.income : TransactionType.expense,
      accountId: account.id,
    ));
  }

  return ImportPreview(
    toImport: toImport,
    duplicates: duplicates,
    mappedToOther: mappedToOther,
    invalid: invalid,
  );
}

/// Appends the previewed transactions in one save, through [TransactionsStore]
/// (ADR-0008).
Future<void> commitImportPreview(ImportPreview preview) async {
  if (preview.hasNothingToImport) return;
  final json = await TransactionsStore.read();
  await TransactionsStore.write([
    ...json,
    ...preview.toImport.map((t) => jsonEncode(t.toJson())),
  ]);
}
