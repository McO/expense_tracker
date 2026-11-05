import 'package:expense_tracker/models/account.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/currency.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/services/account_service.dart';
import 'package:expense_tracker/services/category_service.dart';
import 'package:expense_tracker/services/csv_import.dart';
import 'package:expense_tracker/services/transaction_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Account _acc(String id, Currency c) =>
    Account(id: id, name: 'Acc $id', currency: c, icon: '💳', color: 'FF2196F3');

const _h = csvExportHeader;

void main() {
  late TransactionService svc;
  late Account src;
  late Account dst;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    svc = TransactionService();
    src = _acc('src', Currency.usd);
    dst = _acc('dst', Currency.usd);
    await AccountService().getAccounts();
    await CategoryService().getCategories();
  });

  Transaction tx(String id, String title, double amount, TransactionType t,
      {Category? cat, String desc = '', DateTime? date, String acc = 'src'}) {
    return Transaction(
      id: id,
      title: title,
      amount: amount,
      currency: Currency.usd,
      category: cat ?? Category.defaultCategories.first,
      date: date ?? DateTime(2026, 11, 3, 8, 15),
      description: desc,
      type: t,
      accountId: acc,
    );
  }

  Future<List<Transaction>> seedSource() async {
    final rows = [
      tx('1', 'Lunch, with "friends"', 12.5, TransactionType.expense,
          desc: 'line one\nline two, "quoted"'),
      tx('2', 'Salary', 1000, TransactionType.income, cat: Category.defaultCategories[1]),
      tx('3', 'Cash in', 200, TransactionType.income, cat: Category.topUp),
      tx('4', 'Fix', 3.25, TransactionType.expense,
          cat: Category.correction, date: DateTime(2026, 10, 1)),
    ];
    for (final r in rows) {
      await svc.saveTransaction(r);
    }
    return rows;
  }

  test('round trip: export then import into empty account keeps every field', () async {
    await seedSource();
    final csv = (await svc.buildCSV(accountId: 'src'))!;
    final p = await svc.previewImport(csv, dst);
    expect(p.fileError, isNull);
    expect(p.invalid, isEmpty);
    expect(p.toImport.length, 4);
    await svc.commitImport(p);
    final exported = await svc.getTransactionsForAccount('src');
    final imported = await svc.getTransactionsForAccount('dst');
    String key(Transaction t) =>
        '${t.date.year}-${t.date.month}-${t.date.day}|${t.signedAmount.toStringAsFixed(2)}|${t.title}|${t.category.id}|${t.description}';
    expect(imported.map(key).toSet(), exported.map(key).toSet());
    expect(imported.every((t) => t.accountId == 'dst' && t.date.hour == 12), isTrue);
    expect(imported.map((t) => t.id).toSet().length, 4);
    expect(imported.where((t) => t.category.id == Category.topUpId).length, 1);
    expect(imported.where((t) => t.category.id == Category.correctionId).length, 1);
  });

  test('re-importing the same file into the same account yields only duplicates', () async {
    await seedSource();
    final csv = (await svc.buildCSV(accountId: 'src'))!;
    final p = await svc.previewImport(csv, src);
    expect(p.toImport, isEmpty);
    expect(p.duplicates, 4);
    await svc.commitImport(p);
    expect((await svc.getTransactions()).length, 4);
  });

  test('duplicates inside the file are imported as separate rows', () async {
    final csv = '$_h\n2026-11-03,Tea,Food,-2.00,USD,\n2026-11-03,Tea,Food,-2.00,USD,\n';
    final p = await svc.previewImport(csv, dst);
    expect(p.toImport.length, 2);
    expect(p.duplicates, 0);
  });

  test('currency mismatch rejects the whole file and writes nothing', () async {
    final csv = '$_h\n2026-11-03,Tea,Food,-2.00,USD,\n2026-11-04,Tea,Food,-2.00,EUR,\n';
    final p = await svc.previewImport(csv, dst);
    expect(p.fileError, contains('Currency mismatch'));
    expect(p.fileError, contains('EUR'));
    expect(p.toImport, isEmpty);
    await svc.commitImport(p);
    expect(await svc.getTransactions(), isEmpty);
  });

  test('wrong header is rejected', () async {
    final p = await svc.previewImport('Date,Name,Amount\n2026-11-03,x,1\n', dst);
    expect(p.fileError, contains('header'));
    expect((await svc.previewImport('', dst)).fileError, isNotNull);
  });

  test('malformed rows are reported with line numbers; valid rows still import', () async {
    final csv = '$_h\n'
        '2026-11-03,Ok,Food,-2.00,USD,\n'
        '2026-13-45,BadDate,Food,-2.00,USD,\n'
        '2026-11-03,NaN,Food,abc,USD,\n'
        '2026-11-03,Zero,Food,0.00,USD,\n'
        '2026-11-03,Short,Food,-2.00\n'
        '2026-11-05,Ok2,Food,5.00,USD,x\n';
    final p = await svc.previewImport(csv, dst);
    expect(p.toImport.map((t) => t.title), ['Ok', 'Ok2']);
    expect(p.invalid.map((e) => e.line), [3, 4, 5, 6]);
    expect(p.invalid.first.message, contains('date'));
    expect(p.toImport.last.type, TransactionType.income);
    expect(p.toImport.first.type, TransactionType.expense);
    expect(p.toImport.first.amount, 2.0);
  });

  test('line numbers account for multi-line quoted fields', () {
    final recs = parseCsvRecords('a,b\n"x\ny",z\nlast,row\n');
    expect(recs.map((r) => r.line), [1, 2, 4]);
    expect(recs[1].fields, ['x\ny', 'z']);
  });

  test('unknown categories map to Other and are counted; export names map back', () async {
    final csv = '$_h\n'
        '2026-11-03,A,Nonsense,-1.00,USD,\n'
        '2026-11-03,B,food,-1.00,USD,\n'
        '2026-11-03,C,Top-up,10.00,USD,\n'
        '2026-11-03,D,Correction,-1.00,USD,\n';
    final p = await svc.previewImport(csv, dst);
    expect(p.mappedToOther, 1);
    final byTitle = {for (final t in p.toImport) t.title: t.category.id};
    expect(byTitle, {'A': 'other', 'B': 'food', 'C': 'topup', 'D': 'correction'});
  });

  test('export name wins over name', () {
    const a = Category(id: 'a', name: 'Foo', icon: 'x', color: 'FF000000', exportName: 'Bar');
    const c = Category(id: 'c', name: 'Zed', icon: 'x', color: 'FF000000', exportName: 'Foo');
    expect(matchCategory('foo', [a, c])!.id, 'c');
    expect(matchCategory('ZED', [a, c])!.id, 'c');
  });

  test('quoted fields with commas, quotes and newlines parse', () async {
    final csv = '$_h\r\n2026-11-03,"A, ""B""","Food",-1.50,USD,"l1\nl2"\r\n';
    final p = await svc.previewImport(csv, dst);
    expect(p.invalid, isEmpty);
    expect(p.toImport.single.title, 'A, "B"');
    expect(p.toImport.single.description, 'l1\nl2');
  });
}
