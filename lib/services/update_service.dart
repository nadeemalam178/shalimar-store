import 'dart:convert';
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

  const ReleaseUpdateInfo({
    required this.hasUpdate,
    this.latestVersion = '',
    this.title = '',
    this.changelog = '',
    this.downloadUrl = '',
  });
}

class UpdateService {
  static const String _githubRepo = 'nadeemalam178/Shalimar-Store';
  static const String _currentVersionTag = AppConstants.appVersion;

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

      // Find direct APK download link in release assets if available
      String downloadUrl = htmlUrl;
      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        final browserUrl = asset['browser_download_url'] as String? ?? '';
        if (name.endsWith('.apk') && browserUrl.isNotEmpty) {
          // Prefer arm64 or release apk
          if (name.contains('arm64') || name.contains('release') || downloadUrl == htmlUrl) {
            downloadUrl = browserUrl;
          }
        }
      }

      final hasUpdate = isVersionGreater(tagName, _currentVersionTag);

      return ReleaseUpdateInfo(
        hasUpdate: hasUpdate,
        latestVersion: tagName,
        title: title,
        changelog: body,
        downloadUrl: downloadUrl,
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

