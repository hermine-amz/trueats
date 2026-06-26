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

  String displayMessage = message;
  if (displayMessage.startsWith('Exception: ')) {
    displayMessage = displayMessage.substring(11);
  }

  final topPadding = MediaQuery.of(context).padding.top;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (dialogContext) {
      return Positioned(
        top: topPadding + 14,
        left: 18,
        right: 18,
        child: SafeArea(
          bottom: false,
          child: Material(
            color: Colors.transparent,
            child: Align(
              alignment: Alignment.topCenter,
              child: _AppNotificationWidget(
                message: displayMessage,
                title: title,
                type: type,
                onDismiss: () {
                  try {
                    entry.remove();
                  } catch (_) {}
                },
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
}

class _AppNotificationWidget extends StatefulWidget {
  final String message;
  final String? title;
  final AppFeedbackType type;
  final VoidCallback onDismiss;

  const _AppNotificationWidget({
    required this.message,
    required this.title,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_AppNotificationWidget> createState() => _AppNotificationWidgetState();
}

class _AppNotificationWidgetState extends State<_AppNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onDismiss();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _feedbackColor(widget.type);
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double opacity = _animation.value;
        final double yOffset = (1 - _animation.value) * -18;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, yOffset),
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
              child: Icon(_feedbackIcon(widget.type), color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.title != null) ...[
                    Text(
                      widget.title!,
                      style: textTheme.titleLarge?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    widget.message,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.marronFonce),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
        child: SingleChildScrollView(
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
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: 10,
                  overflowSpacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(cancelLabel, textAlign: TextAlign.center),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(confirmLabel, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  return result ?? false;
}
