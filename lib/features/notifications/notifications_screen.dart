import 'package:flutter/material.dart';
import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_feedback.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ServiceLocator.authService.getNotifications();
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.readAt != null) return;
    try {
      await ServiceLocator.authService.markNotificationRead(notification.id);
      _loadNotifications();
    } catch (e) {
      // Ignorer l'erreur silencieusement
    }
  }

  void _showAppealDialog(AppNotification notification) {
    final controller = TextEditingController(
      text: "Je sollicite la réévaluation de mon dossier et la levée des restrictions appliquées sur mon compte.",
    );
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.creme,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.orangeClair,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.gavel_rounded,
                              color: AppColors.terracotta,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Faire un recours",
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Votre recours sera directement transmis à l'administrateur de TruEats pour réévaluation.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: "Votre explication / défense",
                          hintText: "Saisissez votre explication...",
                        ),
                        maxLines: 4,
                        validator: (v) {
                          if (v == null || v.trim().length < 10) {
                            return "Veuillez fournir une explication détaillée (min 10 caract.).";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                              child: const Text("Annuler"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      setDialogState(() {
                                        isSubmitting = true;
                                      });
                                      try {
                                        await ServiceLocator.authService.submitAppeal(
                                          message: controller.text.trim(),
                                        );
                                        if (context.mounted) {
                                          Navigator.of(context).pop();
                                          showAppNotification(
                                            context,
                                            title: "Recours envoyé",
                                            message: "Votre recours a bien été transmis.",
                                            type: AppFeedbackType.success,
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          showAppNotification(
                                            context,
                                            title: "Erreur",
                                            message: e.toString(),
                                            type: AppFeedbackType.error,
                                          );
                                        }
                                      } finally {
                                        setDialogState(() {
                                          isSubmitting = false;
                                        });
                                      }
                                    },
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text("Envoyer"),
                            ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ServiceLocator.authService.currentUser;
    final isSanctioned = currentUser != null &&
        (currentUser.bloqueJusqua != null &&
            currentUser.bloqueJusqua!.isAfter(DateTime.now()));

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        backgroundColor: AppColors.creme,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.marronFonce),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Notifications",
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.terracotta),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.rougeSignalement),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          child: const Text("Réessayer"),
                        ),
                      ],
                    ),
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color: AppColors.grisTexte.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Aucune notification pour le moment",
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.grisTexte,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        itemCount: _notifications.length,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          final isUnread = n.readAt == null;
                          final isSanction = n.type == 'sanction';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isUnread 
                                  ? (isSanction ? AppColors.orangeClair.withValues(alpha: 0.3) : const Color(0xFFFFFDF9))
                                  : const Color(0xFFF7F5F0),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isUnread
                                    ? (isSanction ? AppColors.terracotta.withValues(alpha: 0.5) : AppColors.grisBordure)
                                    : AppColors.grisBordure.withValues(alpha: 0.5),
                                width: isUnread ? 1.5 : 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _markRead(n),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: isSanction 
                                                ? AppColors.rougeSignalement.withValues(alpha: 0.1)
                                                : AppColors.cremeFonce,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isSanction ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                                            color: isSanction ? AppColors.rougeSignalement : AppColors.terracotta,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                n.title,
                                                style: textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppColors.marronFonce,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "${n.createdAt.day.toString().padLeft(2, '0')}/${n.createdAt.month.toString().padLeft(2, '0')} à ${n.createdAt.hour.toString().padLeft(2, '0')}:${n.createdAt.minute.toString().padLeft(2, '0')}",
                                                style: textTheme.bodySmall?.copyWith(
                                                  color: AppColors.grisTexte,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isUnread)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.terracotta,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      n.content,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: AppColors.marronFonce.withValues(alpha: 0.9),
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                    if (isSanction && isSanctioned) ...[
                                      const SizedBox(height: 14),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _showAppealDialog(n),
                                          icon: const Icon(Icons.gavel_rounded, size: 16),
                                          label: const Text("Contester la sanction", style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.terracotta,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            minimumSize: Size.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
