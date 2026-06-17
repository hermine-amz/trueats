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
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _currentPasswordController;
  late String _selectedSexe;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.user.nom);
    _prenomController = TextEditingController(text: widget.user.prenom);
    _emailController = TextEditingController(text: widget.user.email);
    String initialPhone = widget.user.telephone ?? "";
    if (initialPhone.startsWith("+229")) {
      initialPhone = initialPhone.substring(4).trim();
    }
    _phoneController = TextEditingController(text: initialPhone);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _selectedSexe = (widget.user.sexe == "Masculin" || widget.user.sexe == "Féminin")
        ? widget.user.sexe
        : "Féminin";

    _emailController.addListener(_onSensitiveFieldChanged);
    _passwordController.addListener(_onSensitiveFieldChanged);
  }

  void _onSensitiveFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.removeListener(_onSensitiveFieldChanged);
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.removeListener(_onSensitiveFieldChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
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
      final tel = _phoneController.text.trim().replaceAll(' ', '');
      final telephoneComplet = tel.isNotEmpty ? '+229$tel' : null;

      await ServiceLocator.authService.updateProfile(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        sexe: _selectedSexe,
        telephone: telephoneComplet,
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text.isEmpty ? null : _confirmPasswordController.text,
        currentPassword: _currentPasswordController.text.isEmpty ? null : _currentPasswordController.text,
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
    final isSensitiveChange = _emailController.text.trim() != widget.user.email ||
        _passwordController.text.isNotEmpty;

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
                      "INFORMATIONS GENERALES",
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
                        DropdownMenuItem(value: "Féminin", child: Text("Féminin")),
                        DropdownMenuItem(value: "Masculin", child: Text("Masculin")),
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
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Numéro de téléphone",
                        hintText: "01 XX XX XX XX",
                        prefixIcon: Icon(Icons.phone_outlined),
                        prefixText: "+229  ",
                        prefixStyle: TextStyle(
                          color: AppColors.terracotta,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        final cleaned = value.replaceAll(' ', '');
                        if (!RegExp(r'^01[0-9]{8}$').hasMatch(cleaned)) {
                          return "Format invalide — ex: 0197123456";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    Text(
                      "SÉCURITÉ & CONNEXION",
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.terracotta,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
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
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: "Nouveau mot de passe (optionnel)",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 8) {
                          return "Le mot de passe doit faire au moins 8 caractères";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: "Confirmer le nouveau mot de passe",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (_passwordController.text.isNotEmpty &&
                            value != _passwordController.text) {
                          return "Les mots de passe ne correspondent pas";
                        }
                        return null;
                      },
                    ),
                    if (isSensitiveChange) ...[
                      const SizedBox(height: 28),
                      Text(
                        "VALIDATION REQUISE",
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.rougeSignalement,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Vous modifiez des informations sensibles. Veuillez saisir votre mot de passe actuel pour valider.",
                        style: textTheme.bodySmall?.copyWith(color: AppColors.grisTexte),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPassword,
                        decoration: InputDecoration(
                          labelText: "Mot de passe actuel",
                          prefixIcon: const Icon(Icons.shield_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Le mot de passe actuel est requis";
                          }
                          return null;
                        },
                      ),
                    ],
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
