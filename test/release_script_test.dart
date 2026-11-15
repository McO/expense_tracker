import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Runs tool/release.sh --dry-run with fake `firebase` / `gh` on PATH.
Future<ProcessResult> _dryRun({
  String? envFileContent,
  int firebaseLoginExit = 0,
  String skip = 'branch,clean,sync,gh,key,firebase',
}) async {
  final tmp = Directory.systemTemp.createTempSync('release_script_test');
  addTearDown(() => tmp.deleteSync(recursive: true));
  final bin = Directory('${tmp.path}/bin')..createSync();
  File('${bin.path}/firebase')
    ..writeAsStringSync('#!/bin/sh\n[ "\$1" = login:list ] && exit $firebaseLoginExit\necho REAL-UPLOAD >&2\nexit 9\n')
    ..createSync();
  File('${bin.path}/gh').writeAsStringSync('#!/bin/sh\nexit 0\n');
  await Process.run('chmod', ['+x', '${bin.path}/firebase', '${bin.path}/gh']);
  final env = <String, String>{
    'PATH': '${bin.path}:${Platform.environment['PATH']}',
    'RELEASE_DRY_RUN_SKIP_CHECKS': skip,
    'RELEASE_LOCAL_ENV': '${tmp.path}/absent.env',
  };
  if (envFileContent != null) {
    File('${tmp.path}/release.local.env').writeAsStringSync(envFileContent);
    env['RELEASE_LOCAL_ENV'] = '${tmp.path}/release.local.env';
  }
  return Process.run(
    'bash',
    ['tool/release.sh', 'patch', '--dry-run'],
    environment: env,
  );
}

void main() {
  test('without config the release skips Firebase with one line', () async {
    final r = await _dryRun();
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stdout, contains('Firebase distribution not configured; skipped'));
    expect(r.stdout, isNot(contains('appdistribution')));
  });

  test('with config a dry run prints the exact distribute command', () async {
    final r = await _dryRun(
      envFileContent: 'FIREBASE_APP_ID=1:123:android:abc\nFIREBASE_TESTER_GROUP=testers\n',
    );
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(
      r.stdout,
      matches(RegExp(
        r'would run: firebase appdistribution:distribute build/release/expense-tracker-\d+\.\d+\.\d+\.apk '
        r'--app 1:123:android:abc --groups testers --release-notes-file \S+',
      )),
    );
    expect(r.stdout, isNot(contains('not configured')));
    expect(r.stderr, isNot(contains('REAL-UPLOAD')));
  });

  test('a logged-out firebase CLI is refused before anything changes', () async {
    final r = await _dryRun(
      envFileContent: 'FIREBASE_APP_ID=1:123:android:abc\nFIREBASE_TESTER_GROUP=testers\n',
      firebaseLoginExit: 1,
      skip: 'branch,clean,sync,gh,key',
    );
    expect(r.exitCode, isNot(0));
    expect(r.stderr, contains('not logged in'));
    expect(r.stdout, isNot(contains('2/8 Version')));
  });
}
