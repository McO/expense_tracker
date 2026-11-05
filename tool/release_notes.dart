// Version arithmetic and changelog generation for tool/release.sh.
//
// CLI (used by the script):
//   dart tool/release_notes.dart next <pubspec.yaml> <major|minor|patch|X.Y.Z>
//       prints the new "X.Y.Z+N" version (does not write anything)
//   git log --format=%s <range> | dart tool/release_notes.dart section <X.Y.Z> <YYYY-MM-DD>
//       prints the changelog section for the subjects read from stdin
//   dart tool/release_notes.dart prepend <CHANGELOG.md> <section-file>
//       prepends the section file's text to the changelog (creates it if missing)
import 'dart:io';

class _Version {
  _Version(this.major, this.minor, this.patch, [this.build]);
  final int major, minor, patch;
  final int? build;

  int compareCore(_Version o) {
    if (major != o.major) return major.compareTo(o.major);
    if (minor != o.minor) return minor.compareTo(o.minor);
    return patch.compareTo(o.patch);
  }

  String get core => '$major.$minor.$patch';
}

final _coreRe = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');
final _fullRe = RegExp(r'^(\d+)\.(\d+)\.(\d+)\+(\d+)$');

/// Computes the new `X.Y.Z+N` from the [current] pubspec version and the
/// [arg] (`major`, `minor`, `patch` or an explicit `X.Y.Z` that must be
/// greater than the current one). The build number always increments by one.
/// Throws [FormatException] on bad input.
String bumpVersion(String current, String arg) {
  final m = _fullRe.firstMatch(current.trim());
  if (m == null) {
    throw FormatException(
      'Current version "$current" is not of the form X.Y.Z+N',
    );
  }
  final cur = _Version(
    int.parse(m[1]!),
    int.parse(m[2]!),
    int.parse(m[3]!),
    int.parse(m[4]!),
  );
  final _Version next;
  switch (arg) {
    case 'major':
      next = _Version(cur.major + 1, 0, 0);
    case 'minor':
      next = _Version(cur.major, cur.minor + 1, 0);
    case 'patch':
      next = _Version(cur.major, cur.minor, cur.patch + 1);
    default:
      final e = _coreRe.firstMatch(arg);
      if (e == null) {
        throw FormatException(
          'Bump "$arg" must be major, minor, patch or X.Y.Z',
        );
      }
      next = _Version(int.parse(e[1]!), int.parse(e[2]!), int.parse(e[3]!));
      if (next.compareCore(cur) <= 0) {
        throw FormatException(
          'Version $arg must be greater than the current ${cur.core}',
        );
      }
  }
  return '${next.core}+${cur.build! + 1}';
}

class ChangelogEntry {
  ChangelogEntry(this.type, this.summary, this.taskIds);
  final String type;
  final String summary;
  final List<String> taskIds;
}

final _subjectRe = RegExp(
  r'^([a-z]+)(?:\(([^)]+)\))?: (.+?)((?: \[[a-z0-9]+(?:-[a-z0-9]+)*\])+)$',
);
final _idRe = RegExp(r'\[([^\]]+)\]');

const _excludedTypes = {'model'};
final _excludedSummaries = <RegExp>[
  RegExp(r'^batch start$'),
  RegExp(r'^work session end bookkeeping$'),
  RegExp(r'^capture\b'),
  RegExp(r'^index ADR-'),
  RegExp(r'^task bounced\b'),
  RegExp(r'^reconcile\b'),
];

/// Parses one commit subject; returns null when it is not a task-completion
/// commit (no `[<task-id>]` trailer, or batch-start / bookkeeping / capture /
/// modeling / index / bounce / release commits).
ChangelogEntry? parseSubject(String subject) {
  final m = _subjectRe.firstMatch(subject.trim());
  if (m == null) return null;
  final type = m[1]!;
  final scope = m[2];
  final summary = m[3]!.trim();
  if (_excludedTypes.contains(type)) return null;
  if (type == 'chore' && scope == 'release') return null;
  if (_excludedSummaries.any((r) => r.hasMatch(summary))) return null;
  final ids = _idRe.allMatches(m[4]!).map((x) => x[1]!).toList();
  return ChangelogEntry(type, summary, ids);
}

String _group(String type) {
  switch (type) {
    case 'feature':
      return 'Features';
    case 'bug':
    case 'fix':
      return 'Fixes';
    case 'refactor':
      return 'Changes';
    default:
      return 'Chores';
  }
}

const _groupOrder = ['Features', 'Fixes', 'Changes', 'Chores'];

/// Renders `## X.Y.Z (date)` for the commit [subjects] (newest first). One
/// bullet per task id; a task appearing in several commits keeps its newest.
String renderSection(String version, String date, List<String> subjects) {
  final seen = <String>{};
  final groups = {for (final g in _groupOrder) g: <String>[]};
  for (final s in subjects) {
    final e = parseSubject(s);
    if (e == null) continue;
    final key = e.taskIds.join(',');
    if (!seen.add(key)) continue;
    groups[_group(e.type)]!.add('- ${e.summary} (${e.taskIds.join(', ')})');
  }
  final b = StringBuffer('## $version ($date)\n');
  var any = false;
  for (final g in _groupOrder) {
    if (groups[g]!.isEmpty) continue;
    any = true;
    b.write('\n### $g\n');
    for (final line in groups[g]!) {
      b.write('$line\n');
    }
  }
  if (!any) b.write('\n_No task changes._\n');
  return b.toString();
}

/// Prepends [section] to an existing changelog text, below the
/// `# Changelog` header; creates the header for an empty file.
String prependSection(String existing, String section) {
  const header = '# Changelog';
  final sec = section.endsWith('\n') ? section : '$section\n';
  if (existing.trim().isEmpty) return '$header\n\n$sec';
  if (existing.startsWith(header)) {
    final rest = existing
        .substring(header.length)
        .replaceFirst(RegExp(r'^\s*'), '');
    return '$header\n\n$sec${rest.isEmpty ? '' : '\n$rest'}';
  }
  return '$header\n\n$sec\n$existing';
}

Future<void> main(List<String> args) async {
  try {
    if (args.length == 3 && args[0] == 'next') {
      final text = File(args[1]).readAsStringSync();
      final m = RegExp(
        r'^version:\s*(\S+)\s*$',
        multiLine: true,
      ).firstMatch(text);
      if (m == null) throw const FormatException('No version: line in pubspec');
      stdout.writeln(bumpVersion(m[1]!, args[2]));
    } else if (args.length == 3 && args[0] == 'section') {
      final lines = <String>[];
      String? l;
      while ((l = stdin.readLineSync()) != null) {
        if (l!.trim().isNotEmpty) lines.add(l);
      }
      stdout.write(renderSection(args[1], args[2], lines));
    } else if (args.length == 3 && args[0] == 'prepend') {
      final f = File(args[1]);
      final existing = f.existsSync() ? f.readAsStringSync() : '';
      f.writeAsStringSync(
        prependSection(existing, File(args[2]).readAsStringSync()),
      );
    } else {
      stderr.writeln('usage: release_notes.dart next|section|prepend ...');
      exit(64);
    }
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    exit(1);
  }
}
