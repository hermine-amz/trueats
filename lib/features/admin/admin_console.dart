import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';

class AdminConsole extends StatefulWidget {
  const AdminConsole({super.key});

  @override
  State<AdminConsole> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends State<AdminConsole> {
  List<Signalement> _signalements = [];
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final signalements = await ServiceLocator.reviewService.getSignalements();
    final users = await ServiceLocator.authService.getAllUsers();

    if (!mounted) {
      return;
    }

    setState(() {
      _signalements = signalements;
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _resolveSignalement(int signalementId, bool keepReview) async {
    setState(() {
      _isLoading = true;
    });

    await ServiceLocator.reviewService.handleSignalement(
      signalementId,
      keepReview,
    );
    await _loadAdminData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            keepReview
                ? "Le signalement a ete rejete. L'avis est conserve."
                : "L'avis signale a ete retire de la plateforme.",
          ),
          backgroundColor:
              keepReview ? AppColors.sauge : AppColors.rougeSignalement,
        ),
      );
    }
  }

  Future<void> _toggleUser(User user, bool isActive) async {
    await ServiceLocator.authService.setAccountActive(user.id, isActive);
    await _loadAdminData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? "Compte de ${user.name} reactive."
                : "Compte de ${user.name} suspendu.",
          ),
        ),
      );
    }
  }

  void _showAccountsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.creme,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gerer les comptes",
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Activation, suspension et verification rapide des roles.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return _buildUserTile(
                              context,
                              user,
                              onChanged: (value) async {
                                setSheetState(() {
                                  final localIndex = _users.indexWhere(
                                    (item) => item.id == user.id,
                                  );
                                  if (localIndex != -1) {
                                    _users[localIndex] = user.copyWith(
                                      isActive: value,
                                    );
                                  }
                                });
                                await _toggleUser(user, value);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAdminData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CONSOLE ADMIN",
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.grisTexte,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Supervision",
                        style: textTheme.displayLarge?.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          _buildAdminKpiCard(
                            context,
                            _signalements.length.toString(),
                            "A TRAITER",
                            AppColors.rougeSignalement,
                          ),
                          _buildAdminKpiCard(
                            context,
                            "3",
                            "RESTAURANTS",
                            AppColors.terracotta,
                          ),
                          _buildAdminKpiCard(
                            context,
                            _users.length.toString(),
                            "COMPTES",
                            AppColors.marronFonce,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _buildSectionTitle(context, "FILE DE SIGNALEMENTS"),
                      const SizedBox(height: 14),
                      if (_signalements.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: _cardDecoration(),
                          child: const Text("Aucun signalement en attente."),
                        )
                      else
                        ..._signalements.map(
                          (signalement) =>
                              _buildSignalementCard(context, signalement),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showAccountsSheet,
                          icon: const Icon(Icons.people_outline),
                          label: const Text("Gerer les comptes"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cremeFonce,
                            foregroundColor: AppColors.marronFonce,
                            side: const BorderSide(
                              color: AppColors.grisBordure,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.grisTexte,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildAdminKpiCard(
    BuildContext context,
    String value,
    String label,
    Color valueColor,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Text(
              value,
              style: textTheme.displayMedium?.copyWith(
                color: valueColor,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.grisTexte,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalementCard(BuildContext context, Signalement signalement) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.rougeClair,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.rougeSignalement,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signalement.avis.nomAuteur,
                      style: textTheme.titleLarge?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "sur ${signalement.avis.restaurantNom} - il y a ${_getTimeAgo(signalement.dateSignalement)}",
                      style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            signalement.raison,
            style: textTheme.bodyLarge?.copyWith(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _resolveSignalement(signalement.id, false),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text("Retirer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rougeSignalement,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _resolveSignalement(signalement.id, true),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text("Valider"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vertClair,
                    foregroundColor: AppColors.sauge,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(
    BuildContext context,
    User user, {
    required ValueChanged<bool> onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                user.isActive ? AppColors.vertClair : AppColors.rougeClair,
            child: Icon(
              _roleIcon(user.role),
              color:
                  user.isActive ? AppColors.sauge : AppColors.rougeSignalement,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: textTheme.titleLarge?.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  "${user.email} - ${user.role}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: user.isActive,
            activeColor: AppColors.sauge,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(String role) {
    if (role == "admin") {
      return Icons.admin_panel_settings;
    }
    if (role == "gerant") {
      return Icons.restaurant_menu;
    }
    return Icons.person;
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFFDFBF7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.grisBordure),
    );
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 1) {
      return "${diff.inMinutes}m";
    }
    if (diff.inDays < 1) {
      return "${diff.inHours}h";
    }
    return "${diff.inDays}j";
  }
}
