import 'package:flutter_test/flutter_test.dart';

import '../tool/release_notes.dart';

void main() {
  group('bumpVersion', () {
    test('patch', () => expect(bumpVersion('1.0.0+1', 'patch'), '1.0.1+2'));
    test('minor', () => expect(bumpVersion('1.0.0+1', 'minor'), '1.1.0+2'));
    test('major', () => expect(bumpVersion('1.0.0+1', 'major'), '2.0.0+2'));
    test('minor resets patch', () {
      expect(bumpVersion('1.2.3+7', 'minor'), '1.3.0+8');
    });
    test('explicit', () => expect(bumpVersion('1.0.0+1', '1.4.0'), '1.4.0+2'));
    test('equal explicit version is rejected', () {
      expect(() => bumpVersion('1.0.0+1', '1.0.0'), throwsFormatException);
    });
    test('lower explicit version is rejected', () {
      expect(() => bumpVersion('1.4.0+3', '1.3.9'), throwsFormatException);
    });
    test('garbage argument is rejected', () {
      expect(() => bumpVersion('1.0.0+1', 'big'), throwsFormatException);
    });
    test('current version without build number is rejected', () {
      expect(() => bumpVersion('1.0.0', 'patch'), throwsFormatException);
    });
  });

  group('changelog', () {
    const subjects = <String>[
      'chore(infrastructure): batch start [infrastructure-dx7t4]',
      'chore(infrastructure): Release signing done (ADR-0010) [infrastructure-c5nkp]',
      'model(infrastructure): register release tasks [infrastructure-c5nkp] [infrastructure-dx7t4]',
      'chore(cash-ledger): work session end bookkeeping [cash-ledger-hzqaa]',
      'feature(cash-ledger): Import CSV with a preview [cash-ledger-hzqaa]',
      'chore(cash-ledger): capture cash-ledger-hzqaa — Import a CSV [cash-ledger-hzqaa]',
      'chore(cash-ledger): index ADR-0009 [cash-ledger-m47az]',
      'chore: batch start [cash-ledger-ngxsa] [design-system-001]',
      'chore: work session end bookkeeping',
      'chore(cash-ledger): task bounced — Something [cash-ledger-vsszp]',
      'bug(cash-ledger): Summary colours work in dark mode [cash-ledger-p53v9]',
      'fix(cash-ledger): Button says Add movement [cash-ledger-vsszp]',
      'refactor(cash-ledger): Names unified [cash-ledger-ydqbw]',
      'decision(infrastructure): Persistence ADR verified [infrastructure-r5v4d]',
      'feature(cash-ledger): Statistics screen [cash-ledger-bktw5]',
      'feature(cash-ledger): Statistics screen hardened [cash-ledger-bktw5]',
      'chore(release): v1.1.0',
    ];

    test('groups by type, one bullet per task with summary and id', () {
      final s = renderSection('1.1.0', '2026-11-05', subjects);
      expect(s, startsWith('## 1.1.0 (2026-11-05)\n'));
      expect(s.indexOf('### Features'), lessThan(s.indexOf('### Fixes')));
      expect(s.indexOf('### Fixes'), lessThan(s.indexOf('### Changes')));
      expect(s.indexOf('### Changes'), lessThan(s.indexOf('### Chores')));
      expect(s, contains('- Import CSV with a preview (cash-ledger-hzqaa)'));
      expect(
        s,
        contains('- Summary colours work in dark mode (cash-ledger-p53v9)'),
      );
      expect(s, contains('- Button says Add movement (cash-ledger-vsszp)'));
      expect(s, contains('- Names unified (cash-ledger-ydqbw)'));
      expect(
        s,
        contains('- Release signing done (ADR-0010) (infrastructure-c5nkp)'),
      );
      // one bullet per task: first (newest) wins
      expect('cash-ledger-bktw5'.allMatches(s).length, 1);
      expect(s, contains('Statistics screen (cash-ledger-bktw5)'));
    });

    test(
      'excludes batch-start, bookkeeping, capture, modeling, index, bounce',
      () {
        final s = renderSection('1.1.0', '2026-11-05', subjects);
        expect(s, isNot(contains('batch start')));
        expect(s, isNot(contains('bookkeeping')));
        expect(s, isNot(contains('capture')));
        expect(s, isNot(contains('register release tasks')));
        expect(s, isNot(contains('index ADR')));
        expect(s, isNot(contains('bounced')));
        expect(s, isNot(contains('chore(release)')));
        expect(s, isNot(contains('design-system-001')));
      },
    );

    test('first release (whole history) includes everything older too', () {
      final s = renderSection('1.1.0', '2026-11-05', subjects);
      expect(s, contains('Persistence ADR verified (infrastructure-r5v4d)'));
    });

    test('empty list yields a placeholder', () {
      final s = renderSection('1.1.1', '2026-11-06', const []);
      expect(s, contains('No task changes.'));
    });

    test('prepend creates the file with a header', () {
      final out = prependSection('', '## 1.0.1 (d)\n\n- a\n');
      expect(out, startsWith('# Changelog\n\n## 1.0.1 (d)'));
    });

    test('prepend inserts below the header, above older sections', () {
      final old = '# Changelog\n\n## 1.0.0 (d)\n\n- x\n';
      final out = prependSection(old, '## 1.0.1 (d)\n\n- a\n');
      expect(out.indexOf('## 1.0.1'), lessThan(out.indexOf('## 1.0.0')));
      expect(out, startsWith('# Changelog\n'));
    });
  });
}
