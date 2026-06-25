import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ForceUpdateService {
  ForceUpdateService({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  static const String minimumVersionKey = 'minimum_version';
  static const String appStoreUrl = 'https://apps.apple.com/jp/app/id1599151456';

  final FirebaseRemoteConfig _remoteConfig;

  Future<bool> shouldForceUpdate() async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await _remoteConfig.setDefaults(const {minimumVersionKey: ''});
      await _remoteConfig.fetchAndActivate();

      final minimumVersion = _remoteConfig.getString(minimumVersionKey).trim();
      if (minimumVersion.isEmpty) {
        return false;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      return _compareVersions(packageInfo.version, minimumVersion) < 0;
    } catch (_) {
      return false;
    }
  }

  @visibleForTesting
  static int compareVersions(String currentVersion, String minimumVersion) =>
      _compareVersions(currentVersion, minimumVersion);

  static int _compareVersions(String currentVersion, String minimumVersion) {
    final currentParts = _parseVersion(currentVersion);
    final minimumParts = _parseVersion(minimumVersion);
    final maxLength = currentParts.length > minimumParts.length
        ? currentParts.length
        : minimumParts.length;

    for (var index = 0; index < maxLength; index += 1) {
      final currentPart = index < currentParts.length ? currentParts[index] : 0;
      final minimumPart = index < minimumParts.length ? minimumParts[index] : 0;
      if (currentPart != minimumPart) {
        return currentPart.compareTo(minimumPart);
      }
    }

    return 0;
  }

  static List<int> _parseVersion(String version) {
    final normalizedVersion = version.split('+').first;
    return normalizedVersion
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList(growable: false);
  }
}
