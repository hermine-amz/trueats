import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';

class RegisterRestaurantScreen extends StatefulWidget {
  const RegisterRestaurantScreen({super.key});

  @override
  State<RegisterRestaurantScreen> createState() =>
      _RegisterRestaurantScreenState();
}

class _RegisterRestaurantScreenState extends State<RegisterRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _quartierController = TextEditingController();
  final _categoryController = TextEditingController();
  final _typeCuisineController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _rayonController = TextEditingController(text: '150');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _quartierController.dispose();
    _categoryController.dispose();
    _typeCuisineController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _rayonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = ServiceLocator.authService.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isSubmitting = true;
    });

    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final rayon = double.tryParse(_rayonController.text.trim());

    if (latitude == null || longitude == null || rayon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordonnees GPS ou rayon invalides.')),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final newRestaurant = Restaurant(
      id: 0,
      nom: _nameController.text.trim(),
      adresse: _addressController.text.trim(),
      quartier: _quartierController.text.trim(),
      categorie: _categoryController.text.trim().isEmpty
          ? 'Restaurant'
          : _categoryController.text.trim(),
      typeCuisine: _typeCuisineController.text.trim().isEmpty
          ? 'Local'
          : _typeCuisineController.text.trim(),
      logoUrl: null,
      latitude: latitude,
      longitude: longitude,
      qrCode: 'trueats_restaurant_${Random().nextInt(100000)}',
      dateCreation: DateTime.now(),
      menu: const [],
      rayonMetres: rayon,
      gerantId: currentUser.id,
    );

    await ServiceLocator.restaurantService.createRestaurant(newRestaurant);

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newRestaurant.nom} a ete inscrit avec succes.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription restaurant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  'Inscrire un nouveau restaurant',
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 18),
                Text(
                  'Remplissez les informations de votre etablissement afin de le rendre visible sur la plateforme.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _nameController,
                  label: 'Nom du restaurant',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir le nom du restaurant.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: 'Adresse',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir l adresse.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _quartierController,
                  label: 'Quartier',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _categoryController,
                  label: 'Categorie',
                  hintText: 'Maquis, Café, Restaurant...',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _typeCuisineController,
                  label: 'Type de cuisine',
                  hintText: 'Africain, Brunch, Fusion...',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _latitudeController,
                        label: 'Latitude',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Latitude requise.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildTextField(
                        controller: _longitudeController,
                        label: 'Longitude',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Longitude requise.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _rayonController,
                  label: 'Rayon autorise (m)',
                  keyboardType: TextInputType.number,
                  hintText: '100 à 200',
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Inscrire le restaurant'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.grisBordure),
        ),
      ),
    );
  }
}
