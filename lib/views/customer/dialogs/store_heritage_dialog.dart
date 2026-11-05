import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_extensions.dart';

class StoreHeritageDialog extends StatelessWidget {
  const StoreHeritageDialog({super.key});

  Future<void> _launchMaps() async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=Alamganj+Ashok+Rajpath+Patna+800007');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchCall() async {
    final uri = Uri.parse('tel:${AppConstants.ownerPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/${AppConstants.ownerWhatsApp}?text=Hello%20Shalimar%20Store%2C%20I%20have%20an%20inquiry%20regarding%20groceries.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: context.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDark ? 0.35 : 0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Real Store Front Photo with Close Button
                Stack(
                  children: [
                    Image.asset(
                      AppConstants.storeFrontImagePath,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ESTABLISHED 1988 • 35+ YEARS OF TRUST',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF6B4500),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            AppConstants.storeFullName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Content Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // About Description
                      Text(
                        'About Shalimar Store',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Founded in 1988 by Mohammad Jamil, Shalimar General Store is a heritage neighborhood grocery landmark on Ashok Rajpath, Patna. Known for uncompromising quality, authentic spices, pure oils, fresh daily dairy, and personalized doorstep delivery.',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Location & Landmark Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.isDark ? const Color(0xFF262626) : AppColors.surfaceVariant.withAlpha(120),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: context.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              context,
                              Icons.location_on_rounded,
                              'Location',
                              AppConstants.storeAddress,
                            ),
                            Divider(height: 16, color: context.borderSubtle),
                            _buildInfoRow(
                              context,
                              Icons.near_me_rounded,
                              'Landmark',
                              AppConstants.storeLandmark,
                            ),
                            Divider(height: 16, color: context.borderSubtle),
                            _buildInfoRow(
                              context,
                              Icons.access_time_filled_rounded,
                              'Working Hours',
                              AppConstants.storeHours,
                            ),
                            Divider(height: 16, color: context.borderSubtle),
                            _buildInfoRow(
                              context,
                              Icons.qr_code_2_rounded,
                              'Official UPI',
                              AppConstants.ownerUpiId,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _launchWhatsApp,
                              icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                              label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.whatsappGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _launchMaps,
                              icon: const Icon(Icons.map_rounded, size: 16, color: AppColors.primary),
                              label: const Text('Directions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: _launchCall,
                          icon: const Icon(Icons.phone, size: 16, color: Colors.grey),
                          label: Text(
                            'Call Store Directly: ${AppConstants.ownerPhone}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.textSecondary),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

