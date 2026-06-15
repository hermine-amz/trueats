import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_feedback.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _emailController;
  late String _selectedSexe;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.user.nom);
    _prenomController = TextEditingController(text: widget.user.prenom);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedSexe = widget.user.sexe;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Enregistrer les modifications ?',
      message: 'Vos informations de profil seront mises a jour.',
      confirmLabel: 'Enregistrer',
      icon: Icons.edit_outlined,
      type: AppFeedbackType.info,
    );
    if (!confirmed) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ServiceLocator.authService.updateProfile(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        sexe: _selectedSexe,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
      Navigator.of(context).pop(true);
      showAppNotification(
        context,
        title: 'Profil mis a jour',
        message: "Vos informations de profil ont ete modifiees.",
        type: AppFeedbackType.success,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        showAppNotification(
          context,
          title: 'Erreur',
          message: "Erreur lors de la mise a jour : $e",
          type: AppFeedbackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(title: const Text("Editer profil")),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "INFORMATIONS",
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.terracotta,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Modifier mes informations",
                      style: textTheme.displayMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: "Prenom",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: "Nom",
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedSexe,
                      decoration: const InputDecoration(
                        labelText: "Sexe",
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Femme", child: Text("Femme")),
                        DropdownMenuItem(value: "Homme", child: Text("Homme")),
                        DropdownMenuItem(
                          value: "Non precise",
                          child: Text("Prefere ne pas preciser"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedSexe = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Champ requis";
                        }
                        if (!RegExp(
                          r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value.trim())) {
                          return "Email invalide";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text("Enregistrer"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Champ requis";
    }
    return null;
  }
}
