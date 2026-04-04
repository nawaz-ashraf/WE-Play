List<int> _parseVersion(String version) {
  return version
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList(growable: false);
}

int _compareVersions(String a, String b) {
  final aParts = _parseVersion(a);
  final bParts = _parseVersion(b);
  final maxLength =
      aParts.length > bParts.length ? aParts.length : bParts.length;

  for (var i = 0; i < maxLength; i++) {
    final aValue = i < aParts.length ? aParts[i] : 0;
    final bValue = i < bParts.length ? bParts[i] : 0;

    if (aValue > bValue) {
      return 1;
    }
    if (aValue < bValue) {
      return -1;
    }
  }

  return 0;
}

bool isVersionGreaterThan(String candidate, String baseline) {
  return _compareVersions(candidate, baseline) > 0;
}

bool isVersionAtLeast(String candidate, String baseline) {
  return _compareVersions(candidate, baseline) >= 0;
}
