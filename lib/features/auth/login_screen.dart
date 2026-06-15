import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../navigation/main_navigation.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildQuickLoginButton(String label, String email) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.creme,
      labelStyle: const TextStyle(
        color: AppColors.terracotta,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.terracotta, width: 1),
      ),
      onPressed: () {
        setState(() {
          _emailController.text = email;
          _passwordController.text = "password";
        });
      },
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final success = await ServiceLocator.authService.login(email, password);
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur de connexion : $e"),
            backgroundColor: AppColors.rougeSignalement,
          ),
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
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 20.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // En-tête de marque : Logo T + TruEats
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: AppColors.terracotta,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "T",
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "TruEats",
                            style: textTheme.displaySmall?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Label BIENVENUE
                      Text(
                        "CONNEXION",
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.terracotta.withValues(alpha: 0.8),
                          fontSize: 13,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Slogan : L'avis qu'on peut croire. (RichText)
                      RichText(
                        text: TextSpan(
                          style: textTheme.displayLarge?.copyWith(
                            fontSize: 34,
                            height: 1.25,
                          ),
                          children: const [
                            TextSpan(text: "L'avis qu'on\n"),
                            TextSpan(
                              text: "peut croire.",
                              style: TextStyle(color: AppColors.terracotta),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        "Connectez-vous pour publier des avis et rechercher des restaurants en fonction de vos budgets.",
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.grisTexte,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Champ Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: "Adresse e-mail",
                          hintText: "client@trueats.com ou tanti@trueats.com",
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Veuillez entrer votre e-mail";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Champ Mot de passe
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: "Mot de passe",
                          hintText: "Saisissez votre mot de passe",
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
                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      // Bouton Se Connecter
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
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
                            : Text(
                                "Se connecter",
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),

                      const SizedBox(height: 20),

                      // Helper Card for login credentials
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cremeFonce,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.grisBordure),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Comptes de test (Cliquez pour remplir) :",
                              style: textTheme.labelLarge?.copyWith(
                                color: AppColors.marronFonce,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildQuickLoginButton("Client", "client@trueats.com"),
                                _buildQuickLoginButton("Tanti (Gérant)", "tanti@trueats.com"),
                                _buildQuickLoginButton("Bissap (Gérant)", "bissap@trueats.com"),
                                _buildQuickLoginButton("Admin", "admin@trueats.com"),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      //mot de passe oublié
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ResetPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Mot de passe oublié ?",
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Pas de compte ? S'inscrire
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Vous n'avez pas de compte ? ",
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.grisTexte,
                              fontSize: 15,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "S'inscrire",
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
      ),
    );
  }
}
