import 'package:package_info_plus/package_info_plus.dart';

/// The installed app's version name and build number.
class AppVersion {
  final String name;
  final String buildNumber;
  const AppVersion(this.name, this.buildNumber);

  /// Display form, e.g. `Version 1.1.0 (2)`.
  String get label => 'Version $name ($buildNumber)';
}

/// Looks up the installed version; null when unavailable. A seam so tests
/// can supply a fixed version.
typedef AppVersionLookup = Future<AppVersion?> Function();

/// Default lookup backed by the installed package (pubspec version X.Y.Z+N).
Future<AppVersion?> lookupAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  return AppVersion(info.version, info.buildNumber);
}
