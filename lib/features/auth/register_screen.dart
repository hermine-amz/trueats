import 'package:flutter/material.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../navigation/main_navigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // Le téléphone est séparé du préfixe pour simplifier la validation
  final _telephoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedSexe = "Féminin";
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tel = _telephoneController.text.trim();
      // On envoie le numéro complet avec l'indicatif
      final telephoneComplet = tel.isNotEmpty ? '+229$tel' : null;

      final success = await ServiceLocator.authService.register(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        sexe: _selectedSexe,
        telephone: telephoneComplet,
      );

      if (success && mounted) {
        showAppNotification(
          context,
          title: "Inscription réussie",
          message: "Bienvenue sur TruEats !",
          type: AppFeedbackType.success,
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppNotification(
          context,
          title: "Erreur d'inscription",
          message: e.toString(),
          type: AppFeedbackType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Image.asset(
                        'assets/logo_transparent.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      "Inscription",
                      style: textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        color: AppColors.marronFonce,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Créez un compte pour publier des avis vérifiés et trouver des restaurants selon votre budget.",
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.grisTexte,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _prenomController,
                            labelText: "Prénom",
                            hintText: "Ex: Sophie",
                            icon: Icons.person_outline_rounded,
                            validatorMessage: "Entrez votre prénom",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _nomController,
                            labelText: "Nom",
                            hintText: "Ex: Martin",
                            icon: Icons.badge_outlined,
                            validatorMessage: "Entrez votre nom",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSexe,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.wc_outlined),
                        labelText: "Sexe",
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
                    const SizedBox(height: 16),
                    // Champ téléphone avec préfixe béninois fixe
                    TextFormField(
                      controller: _telephoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: "Numéro de téléphone",
                        hintText: "01 XX XX XX XX",
                        prefixIcon: Icon(Icons.phone_outlined),
                        // Le +229 est affiché en préfixe fixe — l'utilisateur
                        // saisit juste les 10 chiffres locaux
                        prefixText: "+229  ",
                        prefixStyle: TextStyle(
                          color: AppColors.terracotta,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          // Le téléphone est optionnel
                          return null;
                        }
                        // Format béninois : 01 + 8 chiffres = 10 chiffres
                        final cleaned = value.replaceAll(' ', '');
                        if (!RegExp(r'^01[0-9]{8}$').hasMatch(cleaned)) {
                          return "Format invalide — ex: 0197123456";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: "Adresse e-mail",
                        hintText: "Ex: marie@exemple.fr",
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Veuillez entrer votre adresse e-mail";
                        }
                        if (!RegExp(
                          r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value.trim())) {
                          return "Veuillez entrer une adresse e-mail valide";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: "Mot de passe",
                        hintText: "Au moins 6 caractères",
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.grisTexte,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Veuillez entrer votre mot de passe";
                        }
                        if (value.length < 6) {
                          return "Le mot de passe doit faire au moins 6 caractères";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleRegister(),
                      decoration: InputDecoration(
                        labelText: "Confirmer le mot de passe",
                        hintText: "Ressaisissez le mot de passe",
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.grisTexte,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Veuillez confirmer votre mot de passe";
                        }
                        if (value != _passwordController.text) {
                          return "Les mots de passe ne correspondent pas";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text("S'inscrire"),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Deja un compte ? ",
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.grisTexte,
                            fontSize: 15,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            "Se connecter",
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.terracotta,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    required String validatorMessage,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validatorMessage;
        }
        return null;
      },
    );
  }
}
