import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../auth/login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  int _currentStep = 1; // 1: Reason & Warning, 2: Email request, 3: Code confirmation
  bool _isLoading = false;

  // Step 1 Data
  String _selectedReason = "Je n'utilise plus l'application";
  final TextEditingController _commentController = TextEditingController();
  List<String> _reasons = [
    "Je n'utilise plus l'application",
    "J'ai créé un autre compte",
    "Problèmes de confidentialité",
    "L'application ne me convient pas",
    "Autre"
  ];

  // Step 2 Data
  final TextEditingController _emailController = TextEditingController();

  // Step 3 Data
  final TextEditingController _codeController = TextEditingController();
  Timer? _timer;
  int _timerSeconds = 900; // 15 minutes

  @override
  void initState() {
    super.initState();
    final user = ServiceLocator.authService.currentUser;
    if (user?.role == 'admin') {
      _reasons = [
        "Je quitte mes fonctions d'administrateur",
        "Je n'ai plus besoin d'accéder à la console",
        "Problèmes de sécurité du compte",
        "Autre"
      ];
      _selectedReason = _reasons.first;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timerSeconds = 900;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds <= 0) {
        timer.cancel();
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  String _formatTimer() {
    final minutes = (_timerSeconds / 60).floor();
    final seconds = _timerSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _requestVerificationCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showAppNotification(
        context,
        title: "Erreur",
        message: "Veuillez entrer votre adresse e-mail.",
        type: AppFeedbackType.error,
      );
      return;
    }

    final currentUser = ServiceLocator.authService.currentUser;
    if (currentUser != null && currentUser.email.toLowerCase() != email.toLowerCase()) {
      showAppNotification(
        context,
        title: "Erreur",
        message: "L'e-mail saisi ne correspond pas à celui de ce compte.",
        type: AppFeedbackType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ServiceLocator.authService.requestAccountDeletion(
        email: email,
        reason: _selectedReason,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _currentStep = 3;
      });
      _startTimer();
      showAppNotification(
        context,
        title: "Code envoyé",
        message: "Un code de vérification à 6 chiffres a été envoyé sur votre adresse e-mail.",
        type: AppFeedbackType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showAppNotification(
        context,
        title: "Erreur",
        message: e.toString(),
        type: AppFeedbackType.error,
      );
    }
  }

  Future<void> _confirmDeletion() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length != 6) {
      showAppNotification(
        context,
        title: "Erreur",
        message: "Veuillez entrer un code de vérification valide à 6 chiffres.",
        type: AppFeedbackType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ServiceLocator.authService.confirmAccountDeletion(code: code);

      if (!mounted) return;

      showAppNotification(
        context,
        title: "Compte désactivé",
        message: "Votre compte a été désactivé. Vous avez 30 jours pour vous reconnecter et annuler la suppression.",
        type: AppFeedbackType.success,
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showAppNotification(
        context,
        title: "Erreur",
        message: e.toString(),
        type: AppFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        backgroundColor: AppColors.creme,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.marronFonce),
          onPressed: () {
            if (_currentStep > 1 && !_isLoading) {
              setState(() {
                _currentStep--;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          "Suppression du compte",
          style: textTheme.displayMedium?.copyWith(fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepIndicator(),
                    const SizedBox(height: 24),
                    if (_currentStep == 1) _buildStep1(textTheme),
                    if (_currentStep == 2) _buildStep2(textTheme),
                    if (_currentStep == 3) _buildStep3(textTheme),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, "Raisons"),
        _buildStepDivider(),
        _buildStepCircle(2, "Identité"),
        _buildStepDivider(),
        _buildStepCircle(3, "Validation"),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.terracotta : AppColors.grisBordure,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: _currentStep == step ? FontWeight.bold : FontWeight.normal,
              color: _currentStep == step ? AppColors.marronFonce : AppColors.grisTexte,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 40,
      height: 2,
      color: AppColors.grisBordure,
    );
  }

  Widget _buildStep1(TextTheme textTheme) {
    final user = ServiceLocator.authService.currentUser;
    final isGerant = user?.role == 'gerant';
    final isAdmin = user?.role == 'admin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.vertClair.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.vertClair),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.marronFonce, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Note : Votre compte sera désactivé immédiatement. Vous aurez 30 jours pour annuler cette action en vous reconnectant simplement à l'application. Passé ce délai, la suppression sera définitive.",
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.marronFonce,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grisBordure),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.rougeSignalement, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Qu'allez-vous perdre ?",
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.rougeSignalement,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isAdmin) ...[
                _buildLossItem(Icons.admin_panel_settings_outlined, "Votre accès complet d'administration à la console de gestion TrueAts."),
                _buildLossItem(Icons.gavel_rounded, "La possibilité de valider/rejeter les restaurants et de modérer les signalements."),
                _buildLossItem(Icons.block_flipped, "Le droit de bloquer/débloquer ou supprimer des utilisateurs de l'application."),
                _buildLossItem(Icons.history_toggle_off_rounded, "L'historique et le traçage complet de vos actions administratives passées."),
              ] else ...[
                _buildLossItem(Icons.star_outline_rounded, "Tous les avis que vous avez rédigés sur les restaurants."),
                _buildLossItem(Icons.bookmark_outline_rounded, "Vos listes de favoris et adresses à explorer."),
                if (isGerant)
                  _buildLossItem(Icons.storefront_outlined, "Les restaurants que vous gérez ainsi que leurs cartes/menus associés."),
              ],
              _buildLossItem(Icons.person_outline_rounded, "Vos informations de profil et votre historique de connexion."),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          "Pourquoi souhaitez-vous nous quitter ?",
          style: textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grisBordure),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedReason,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.terracotta),
              items: _reasons.map((reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedReason = val;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "Commentaire additionnel (Optionnel)",
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Dites-nous en plus pour nous aider à nous améliorer...",
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.grisTexte),
            fillColor: const Color(0xFFFDFBF7),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.grisBordure),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.terracotta),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 2;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rougeSignalement,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Continuer vers la suppression", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildLossItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.grisTexte, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.grisTexte),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.security, size: 48, color: AppColors.terracotta),
        const SizedBox(height: 16),
        Text(
          "Confirmation de votre identité",
          style: textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "Par sécurité, veuillez saisir l'adresse e-mail associée à votre compte TruEats. Après validation, votre compte sera désactivé et mis en attente de suppression pendant 30 jours.",
          style: TextStyle(fontSize: 14, color: AppColors.grisTexte),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Adresse e-mail du compte",
            labelStyle: const TextStyle(color: AppColors.grisTexte),
            fillColor: const Color(0xFFFDFBF7),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.grisBordure),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.terracotta),
            ),
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.terracotta),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _requestVerificationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.terracotta,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Recevoir le code par e-mail", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.mark_email_unread_outlined, size: 48, color: AppColors.terracotta),
        const SizedBox(height: 16),
        Text(
          "Saisir le code de confirmation",
          style: textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Veuillez saisir le code à 6 chiffres envoyé à l'adresse ${_emailController.text} pour confirmer la désactivation temporaire de votre compte (période de réflexion de 30 jours).",
          style: const TextStyle(fontSize: 14, color: AppColors.grisTexte),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: InputDecoration(
            counterText: "",
            hintText: "000000",
            hintStyle: TextStyle(color: AppColors.grisBordure.withValues(alpha: 0.5)),
            fillColor: const Color(0xFFFDFBF7),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.grisBordure),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.terracotta),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            "Le code expire dans : ${_formatTimer()}",
            style: const TextStyle(fontSize: 13, color: AppColors.rougeSignalement, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirmDeletion,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rougeSignalement,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text("Confirmer la suppression", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _requestVerificationCode,
            child: const Text("Renvoyer le code", style: TextStyle(color: AppColors.terracotta, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
