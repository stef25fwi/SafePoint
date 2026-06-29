import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showNotification;
  final int alertCount;
  final bool showBack;
  final VoidCallback? onNotificationTap;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showNotification = true,
    this.alertCount = 0,
    this.showBack = false,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          if (showBack) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 18, color: AppColors.blue),
              ),
            ),
            const SizedBox(width: 10),
          ],
          _VolcanoLogo(size: showBack ? 36 : 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (showNotification)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      size: 26, color: AppColors.textSecondary),
                  onPressed: onNotificationTap,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                if (alertCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          alertCount > 9 ? '9+' : '$alertCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _VolcanoLogo extends StatelessWidget {
  final double size;
  const _VolcanoLogo({this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.volcano,
          color: Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }
}

// Standalone logo widget for login
class VolcanoLogo extends StatelessWidget {
  final double size;
  const VolcanoLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(Icons.volcano, color: Colors.white, size: size * 0.55),
      ),
    );
  }
}
