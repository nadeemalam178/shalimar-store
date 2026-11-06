import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';

class ReleaseUpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String title;
  final String changelog;
  final String downloadUrl;
  final String architecture;

  const ReleaseUpdateInfo({
    required this.hasUpdate,
    this.latestVersion = '',
    this.title = '',
    this.changelog = '',
    this.downloadUrl = '',
    this.architecture = 'arm64-v8a',
  });
}

class UpdateService {
  static const String _githubRepo = 'nadeemalam178/Shalimar-Store';
  static const String _currentVersionTag = AppConstants.appVersion;

  /// Resolves the exact CPU architecture name of the active device
  static String getDeviceArchitectureName({Abi? targetAbi}) {
    Abi? abi = targetAbi;
    if (abi == null) {
      try {
        abi = Abi.current();
      } catch (_) {
        abi = null;
      }
    }
    if (abi == Abi.androidArm64) return 'arm64-v8a';
    if (abi == Abi.androidArm) return 'armeabi-v7a';
    if (abi == Abi.androidX64) return 'x86_64';
    if (abi == Abi.androidIA32) return 'x86';
    return 'arm64-v8a';
  }

  /// Selects the device-architecture-matching APK URL from release assets
  static String selectBestApkUrl(
    List<dynamic> assets,
    String defaultUrl, {
    Abi? targetAbi,
  }) {
    String? arm64Url;
    String? armV7Url;
    String? x8664Url;
    String? universalUrl;

    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      final name = (asset['name'] as String? ?? '').toLowerCase();
      final browserUrl = asset['browser_download_url'] as String? ?? '';
      if (!name.endsWith('.apk') || browserUrl.isEmpty) continue;

      if (name.contains('arm64') || name.contains('v8a')) {
        arm64Url = browserUrl;
      } else if (name.contains('armeabi') || name.contains('v7a') || name.contains('armv7')) {
        armV7Url = browserUrl;
      } else if (name.contains('x86_64') || name.contains('x86-64')) {
        x8664Url = browserUrl;
      } else if (!name.contains('x86')) {
        // Universal APK (e.g., app-release.apk)
        universalUrl = browserUrl;
      }
    }

    Abi? currentAbi = targetAbi;
    if (currentAbi == null) {
      try {
        currentAbi = Abi.current();
      } catch (_) {
        currentAbi = null;
      }
    }

    // 1. Modern Android phones (arm64-v8a)
    if (currentAbi == Abi.androidArm64) {
      return arm64Url ?? armV7Url ?? universalUrl ?? defaultUrl;
    }

    // 2. 32-bit ARM phones (armeabi-v7a)
    if (currentAbi == Abi.androidArm) {
      return armV7Url ?? universalUrl ?? defaultUrl;
    }

    // 3. Android x86_64 (PC Emulators)
    if (currentAbi == Abi.androidX64) {
      return x8664Url ?? universalUrl ?? defaultUrl;
    }

    // 4. Android x86 32-bit Emulators
    if (currentAbi == Abi.androidIA32) {
      return universalUrl ?? defaultUrl;
    }

    // 5. Default fallback for physical Android phones (ARM is overwhelmingly standard)
    // CRITICAL: NEVER serve x86_64 to physical ARM hardware!
    return arm64Url ?? armV7Url ?? universalUrl ?? defaultUrl;
  }

  /// Queries the GitHub Releases API to check if a new version has been released
  static Future<ReleaseUpdateInfo> checkForUpdate() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);

      final uri = Uri.parse('https://api.github.com/repos/$_githubRepo/releases/latest');
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'ShalimarStore-FlutterApp');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != 200) {
        return const ReleaseUpdateInfo(hasUpdate: false);
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      final tagName = data['tag_name'] as String? ?? '';
      final title = data['name'] as String? ?? 'New Store Update Available';
      final body = data['body'] as String? ?? 'Performance improvements and bug fixes.';
      final htmlUrl = data['html_url'] as String? ?? 'https://github.com/$_githubRepo/releases';

      // Find direct matching APK download link in release assets
      final assets = data['assets'] as List<dynamic>? ?? [];
      final downloadUrl = selectBestApkUrl(assets, htmlUrl);
      final archName = getDeviceArchitectureName();

      final hasUpdate = isVersionGreater(tagName, _currentVersionTag);

      return ReleaseUpdateInfo(
        hasUpdate: hasUpdate,
        latestVersion: tagName,
        title: title,
        changelog: body,
        downloadUrl: downloadUrl,
        architecture: archName,
      );
    } catch (_) {
      // Offline or network error - fail silently
      return const ReleaseUpdateInfo(hasUpdate: false);
    }
  }

  static bool isVersionGreater(String remote, String current) {
    if (remote.isEmpty) return false;
    final rClean = remote.replaceAll(RegExp(r'[^0-9.]'), '');
    final cClean = current.replaceAll(RegExp(r'[^0-9.]'), '');

    if (rClean == cClean) return false;

    final rParts = rClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final cParts = cClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final rNum = i < rParts.length ? rParts[i] : 0;
      final cNum = i < cParts.length ? cParts[i] : 0;
      if (rNum > cNum) return true;
      if (rNum < cNum) return false;
    }
    return false;
  }

  /// Downloads the release APK directly inside the app with real-time byte progress
  static Future<void> downloadApkWithProgress({
    required String downloadUrl,
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
    required void Function(String filePath) onComplete,
    required void Function(String error) onError,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/shalimar_store_update.apk';
      final file = File(filePath);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(Uri.parse(downloadUrl));
      request.headers.set('User-Agent', 'ShalimarStore-FlutterApp');
      final response = await request.close();

      if (response.statusCode != 200) {
        onError('Server returned status code: ${response.statusCode}');
        return;
      }

      final totalBytes = response.contentLength;
      int receivedBytes = 0;
      final sink = file.openWrite();

      await response.listen(
        (chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          final progress = totalBytes > 0 ? (receivedBytes / totalBytes) : 0.0;
          onProgress(progress, receivedBytes, totalBytes);
        },
        onError: (e) {
          sink.close();
          onError(e.toString());
        },
        cancelOnError: true,
      ).asFuture();

      await sink.flush();
      await sink.close();
      onComplete(filePath);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Directly launches the native Android package installer without external browser
  static Future<OpenResult> installApk(String filePath) async {
    return await OpenFilex.open(
      filePath,
      type: 'application/vnd.android.package-archive',
    );
  }
}

