import 'package:flutter/material.dart';

import '../theme.dart';

enum AppFeedbackType { success, error, warning, info }

Color _feedbackColor(AppFeedbackType type) {
  switch (type) {
    case AppFeedbackType.success:
      return AppColors.sauge;
    case AppFeedbackType.error:
      return AppColors.rougeSignalement;
    case AppFeedbackType.warning:
      return AppColors.terracotta;
    case AppFeedbackType.info:
      return AppColors.marronFonce;
  }
}

IconData _feedbackIcon(AppFeedbackType type) {
  switch (type) {
    case AppFeedbackType.success:
      return Icons.check_circle_outline_rounded;
    case AppFeedbackType.error:
      return Icons.error_outline_rounded;
    case AppFeedbackType.warning:
      return Icons.warning_amber_rounded;
    case AppFeedbackType.info:
      return Icons.info_outline_rounded;
  }
}

void showAppNotification(
  BuildContext context, {
  required String message,
  String? title,
  AppFeedbackType type = AppFeedbackType.info,
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  final color = _feedbackColor(type);
  final entry = OverlayEntry(
    builder: (context) {
      return Positioned(
        top: MediaQuery.of(context).padding.top + 14,
        left: 18,
        right: 18,
        child: SafeArea(
          bottom: false,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -18, end: 0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (context, offset, child) {
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: AnimatedOpacity(
                    opacity: offset == 0 ? 1 : 0.94,
                    duration: const Duration(milliseconds: 180),
                    child: child,
                  ),
                );
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 640),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_feedbackIcon(type), color: color, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (title != null) ...[
                            Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            message,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.marronFonce),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 3), () {
    if (entry.mounted) entry.remove();
  });
}

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmer',
  String cancelLabel = 'Annuler',
  IconData icon = Icons.help_outline_rounded,
  AppFeedbackType type = AppFeedbackType.warning,
}) async {
  final color = _feedbackColor(type);
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppColors.creme,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(dialogContext)
                              .textTheme
                              .displaySmall
                              ?.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message,
                          style: Theme.of(dialogContext).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(cancelLabel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return result ?? false;
}
