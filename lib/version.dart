/// Single source of truth for the app's version, surfaced in Settings and used
/// by the update/version-tracking system. Keep this in sync with the top entry
/// of RELEASE_NOTES.md and the `version:` field in pubspec.yaml.
library;

/// Human-readable semantic version.
const String kAppVersion = '1.10.0';

/// Monotonically increasing build number.
const int kBuildNumber = 17;

/// A compact identifier combining version and build, e.g. "1.1.0+2".
const String kAppVersionFull = '$kAppVersion+$kBuildNumber';
