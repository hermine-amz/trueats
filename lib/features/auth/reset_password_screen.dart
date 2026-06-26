import 'package:flutter/material.dart';

import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_feedback.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  int _currentStep = 0; // 0: Saisie Email, 1: Saisie Code, 2: Nouveau Mot de passe
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleNextStep() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentStep == 0) {
        await ServiceLocator.authService.sendForgotPasswordCode(
          email: _emailController.text.trim(),
        );
        if (!mounted) return;
        setState(() {
          _currentStep = 1;
        });
        showAppNotification(
          context,
          title: 'Code envoyé',
          message: 'Un code de vérification a été envoyé à votre adresse e-mail.',
          type: AppFeedbackType.success,
        );
      } else if (_currentStep == 1) {
        await ServiceLocator.authService.verifyForgotPasswordCode(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
        );
        if (!mounted) return;
        setState(() {
          _currentStep = 2;
        });
        showAppNotification(
          context,
          title: 'Code vérifié',
          message: 'Veuillez saisir votre nouveau mot de passe.',
          type: AppFeedbackType.success,
        );
      } else if (_currentStep == 2) {
        await ServiceLocator.authService.resetPassword(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        showAppNotification(
          context,
          title: 'Mot de passe réinitialisé',
          message: 'Votre mot de passe a été modifié avec succès.',
          type: AppFeedbackType.success,
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showAppNotification(
          context,
          title: 'Erreur',
          message: e.toString().replaceAll('Exception: ', ''),
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

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        if (_currentStep == 0) {
          _codeController.clear();
        } else if (_currentStep == 1) {
          _passwordController.clear();
          _confirmPasswordController.clear();
        }
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isActive ? 24.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.terracotta
                : (isCompleted ? AppColors.vertClair : AppColors.grisBordure),
            borderRadius: BorderRadius.circular(4.0),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(TextTheme textTheme) {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Mot de passe oublié ?",
              style: textTheme.displayLarge?.copyWith(
                fontSize: 28,
                color: AppColors.marronFonce,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Saisissez l’adresse e-mail de votre compte pour recevoir un code de vérification à 6 chiffres.",
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.grisTexte,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleNextStep(),
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail',
                hintText: 'marie@exemple.fr',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre adresse e-mail';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value.trim())) {
                  return 'Veuillez entrer une adresse e-mail valide';
                }
                return null;
              },
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Code de vérification",
              style: textTheme.displayLarge?.copyWith(
                fontSize: 28,
                color: AppColors.marronFonce,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.grisTexte,
                  fontSize: 14,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: "Saisissez le code de 6 chiffres envoyé à l’adresse :\n"),
                  TextSpan(
                    text: _emailController.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.marronFonce,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleNextStep(),
              maxLength: 6,
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                labelText: 'Code de vérification',
                hintText: '123456',
                prefixIcon: Icon(Icons.lock_outline_rounded),
                counterText: '',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer le code';
                }
                if (value.trim().length != 6) {
                  return 'Le code doit comporter 6 chiffres';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            await ServiceLocator.authService.sendForgotPasswordCode(
                              email: _emailController.text.trim(),
                            );
                            if (mounted) {
                              showAppNotification(
                                context,
                                title: 'Code renvoyé',
                                message: 'Un nouveau code de vérification a été envoyé.',
                                type: AppFeedbackType.success,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              showAppNotification(
                                context,
                                title: 'Erreur',
                                message: e.toString().replaceAll('Exception: ', ''),
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
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.terracotta,
                  ),
                  child: const Text('Renvoyer le code'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                      _codeController.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.grisTexte,
                  ),
                  child: const Text("Modifier l'e-mail"),
                ),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Nouveau mot de passe",
              style: textTheme.displayLarge?.copyWith(
                fontSize: 28,
                color: AppColors.marronFonce,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Créez votre nouveau mot de passe. Il doit comporter au moins 8 caractères.",
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.grisTexte,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                  return 'Veuillez entrer un mot de passe';
                }
                if (value.length < 8) {
                  return 'Le mot de passe doit comporter au moins 8 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleNextStep(),
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                  return 'Veuillez confirmer votre mot de passe';
                }
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _getButtonLabel() {
    switch (_currentStep) {
      case 0:
        return 'Envoyer le code';
      case 1:
        return 'Vérifier le code';
      case 2:
        return 'Réinitialiser le mot de passe';
      default:
        return 'Continuer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
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
                      Center(
                        child: Image.asset(
                          'assets/logo_transparent.png',
                          height: 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildStepIndicator(),
                      const SizedBox(height: 32),
                      _buildStepContent(textTheme),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleNextStep,
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
                                _getButtonLabel(),
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: _isLoading ? null : _handleBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(_currentStep == 0 ? 'Retour à la connexion' : 'Étape précédente'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.terracotta,
                          padding: EdgeInsets.zero,
                        ),
                      ),
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
