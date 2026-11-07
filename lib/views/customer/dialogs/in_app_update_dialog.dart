import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../services/update_service.dart';

class InAppUpdateDialog extends StatefulWidget {
  final ReleaseUpdateInfo updateInfo;
  final bool autoStart;

  static bool _hasPromptedThisSession = false;

  /// Checks for OTA update and displays prompt dialog once per cold-start app session
  static Future<void> checkAndPromptIfAvailable(BuildContext context) async {
    if (_hasPromptedThisSession) return;
    try {
      final info = await UpdateService.checkForUpdate();
      if (!info.hasUpdate) return;
      if (!context.mounted) return;
      _hasPromptedThisSession = true;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => InAppUpdateDialog(
          updateInfo: info,
          autoStart: false,
        ),
      );
    } catch (_) {}
  }

  const InAppUpdateDialog({
    super.key,
    required this.updateInfo,
    this.autoStart = false,
  });

  @override
  State<InAppUpdateDialog> createState() => _InAppUpdateDialogState();
}

class _InAppUpdateDialogState extends State<InAppUpdateDialog> {
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _downloadedFilePath;
  String? _errorMessage;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      _startDownload();
    }
  }

  void _startDownload() {
    setState(() {
      _progress = 0.0;
      _receivedBytes = 0;
      _totalBytes = 0;
      _errorMessage = null;
      _downloadedFilePath = null;
      _isDownloading = true;
    });

    UpdateService.downloadApkWithProgress(
      downloadUrl: widget.updateInfo.downloadUrl,
      onProgress: (progress, received, total) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _receivedBytes = received;
            _totalBytes = total;
          });
        }
      },
      onComplete: (filePath) async {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _downloadedFilePath = filePath;
          });
          // Directly launch native Android package installer
          await UpdateService.installApk(filePath);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _errorMessage = error;
          });
        }
      },
    );
  }

  Future<void> _openExternalFallback() async {
    final uri = Uri.parse(widget.updateInfo.downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).toInt().clamp(0, 100);
    final receivedMb = (_receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = _totalBytes > 0
        ? (_totalBytes / (1024 * 1024)).toStringAsFixed(1)
        : '...';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.isDark ? 0.4 : 0.15,
              ),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Update Available',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.updateInfo.latestVersion,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Shalimar Store Official Release',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isDownloading)
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: context.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Device Architecture Verification Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xFF1E2822)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Target ABI: ${widget.updateInfo.architecture} (Verified for this phone)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.isDark
                            ? const Color(0xFFA5D6A7)
                            : const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Content States
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Download failed: $_errorMessage',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _openExternalFallback,
                      child: const Text('Download in Browser'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startDownload,
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            ] else if (_downloadedFilePath != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Download completed! Android Package Installer launched.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      UpdateService.installApk(_downloadedFilePath!),
                  icon: const Icon(Icons.install_mobile_rounded),
                  label: const Text('Re-launch Package Installer'),
                ),
              ),
            ] else if (_isDownloading) ...[
              // Active Downloading Progress View
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _totalBytes > 0 ? _progress : null,
                  minHeight: 10,
                  backgroundColor: context.borderSubtle,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$receivedMb MB / $totalMb MB',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Downloading update directly... Installer will open automatically.',
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              // Initial Changelog & Details View (User reads what is new first!)
              Text(
                widget.updateInfo.title.isNotEmpty
                    ? widget.updateInfo.title
                    : 'What\'s New in this Update:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Scrollable Changelog Box
              Container(
                constraints: const BoxConstraints(maxHeight: 190),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xFF1E1E1E)
                      : AppColors.surfaceVariant.withAlpha(100),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.borderSubtle),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    widget.updateInfo.changelog.isNotEmpty
                        ? widget.updateInfo.changelog
                        : '• Performance improvements and general bug fixes.\n• Seamless in-app update installation.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Action Buttons: "Later" vs "Download & Install Update"
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: context.borderSubtle),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Later',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _startDownload,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text(
                        'Update Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
