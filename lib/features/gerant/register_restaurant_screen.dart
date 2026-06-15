import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_feedback.dart';

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
  final _superficieController = TextEditingController(text: '150');
  
  // Nouveaux champs textes pour IFU et RCCM
  final _ifuNumeroController = TextEditingController();
  final _rccmNumeroController = TextEditingController();

  // Nouveaux fichiers pour CIP, Attestation IFU, Extrait RCCM
  XFile? _cipFile;
  String? _cipFileName;
  XFile? _ifuAttestationFile;
  String? _ifuAttestationFileName;
  XFile? _rccmExtraitFile;
  String? _rccmExtraitFileName;

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
    _superficieController.dispose();
    _ifuNumeroController.dispose();
    _rccmNumeroController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        final platformFile = result.files.single;
        final name = platformFile.name;
        XFile? xFile;
        if (kIsWeb) {
          if (platformFile.bytes != null) {
            xFile = XFile.fromData(platformFile.bytes!, name: name);
          }
        } else if (platformFile.path != null) {
          xFile = XFile(platformFile.path!);
        }

        if (xFile != null) {
          setState(() {
            if (documentType == 'cip') {
              _cipFile = xFile;
              _cipFileName = name;
            } else if (documentType == 'ifu') {
              _ifuAttestationFile = xFile;
              _ifuAttestationFileName = name;
            } else if (documentType == 'rccm') {
              _rccmExtraitFile = xFile;
              _rccmExtraitFileName = name;
            }
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      showAppNotification(
        context,
        title: 'Erreur',
        message: 'Erreur lors de la sélection du fichier : $e',
        type: AppFeedbackType.error,
      );
    }
  }

  Widget _buildFilePickerTile({
    required String label,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grisBordure),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.marronFonce,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fileName ?? 'Aucun fichier selectionne (PDF, JPG, PNG)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: fileName != null ? AppColors.sauge : AppColors.grisTexte,
                    fontStyle: fileName != null ? FontStyle.normal : FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: fileName != null ? AppColors.vertClair : AppColors.cremeFonce,
              foregroundColor: fileName != null ? AppColors.sauge : AppColors.marronFonce,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            child: Text(fileName != null ? 'Modifier' : 'Choisir'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = ServiceLocator.authService.currentUser;
    if (currentUser == null) return;

    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final superficie = int.tryParse(_superficieController.text.trim());

    if (latitude == null || longitude == null || superficie == null || superficie < 10) {
      showAppNotification(
        context,
        title: 'Validation',
        message: 'Coordonnées GPS ou superficie invalides (min 10 m²).',
        type: AppFeedbackType.warning,
      );
      return;
    }

    // Validation des documents obligatoires pour l'approbation
    if (_cipFile == null) {
      showAppNotification(
        context,
        title: 'Document requis',
        message: 'Le CIP du gérant est obligatoire.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    if (_ifuNumeroController.text.trim().isEmpty || _ifuAttestationFile == null) {
      showAppNotification(
        context,
        title: 'Documents requis',
        message: 'Le numéro IFU et l\'attestation IFU sont requis.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    if (_rccmNumeroController.text.trim().isEmpty || _rccmExtraitFile == null) {
      showAppNotification(
        context,
        title: 'Documents requis',
        message: 'Le numéro RCCM et l\'extrait RCCM sont requis.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String? cipUrl;
    String? ifuAttestationUrl;
    String? rccmExtraitUrl;

    try {
      // Note de soutenance : On televerse les documents justificatifs sensibles
      // sur le serveur Laravel qui restreint l'accès aux administrateurs.
      cipUrl = await ServiceLocator.restaurantService.uploadDocument(
        _cipFile!,
        type: 'cip',
      );
      
      ifuAttestationUrl = await ServiceLocator.restaurantService.uploadDocument(
        _ifuAttestationFile!,
        type: 'ifu_attestation',
      );
      
      rccmExtraitUrl = await ServiceLocator.restaurantService.uploadDocument(
        _rccmExtraitFile!,
        type: 'rccm_extrait',
      );
    } catch (e) {
      if (!mounted) return;
      showAppNotification(
        context,
        title: 'Erreur transfert',
        message: 'Erreur transfert documents : $e',
        type: AppFeedbackType.error,
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
      superficie: superficie,
      rayonMetres: 150.0, // sera recalcule cote backend, requis par le modele
      gerantId: currentUser.id,
      cipUrl: cipUrl,
      ifuNumero: _ifuNumeroController.text.trim(),
      ifuAttestationUrl: ifuAttestationUrl,
      rccmNumero: _rccmNumeroController.text.trim(),
      rccmExtraitUrl: rccmExtraitUrl,
      estValide: false, // creation en attente de validation
    );

    try {
      await ServiceLocator.restaurantService.createRestaurant(newRestaurant);
      
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      Navigator.of(context).pop(true);
      showAppNotification(
        context,
        title: 'Demande soumise',
        message: '${newRestaurant.nom} a été soumis pour validation admin.',
        type: AppFeedbackType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      showAppNotification(
        context,
        title: 'Erreur de création',
        message: 'Erreur création restaurant : $e',
        type: AppFeedbackType.error,
      );
    }
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
                  controller: _superficieController,
                  label: 'Superficie (m²)',
                  keyboardType: TextInputType.number,
                  hintText: 'Ex: 150',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir la superficie.';
                    }
                    final val = int.tryParse(value.trim());
                    if (val == null || val < 10) {
                      return 'Veuillez saisir une superficie superieure a 10 m².';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Documents justificatifs',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.marronFonce,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pour valider votre inscription, vous devez fournir les documents officiels beninois.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                _buildFilePickerTile(
                  label: 'CIP du gerant (PDF ou Image)',
                  fileName: _cipFileName,
                  onTap: () => _pickFile('cip'),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _ifuNumeroController,
                  label: 'Numero IFU (10 chiffres)',
                  keyboardType: TextInputType.number,
                  hintText: 'Ex: 3201234567',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir le numero IFU.';
                    }
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                      return 'Le numero IFU doit comporter exactement 10 chiffres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildFilePickerTile(
                  label: 'Attestation IFU (PDF ou Image)',
                  fileName: _ifuAttestationFileName,
                  onTap: () => _pickFile('ifu'),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _rccmNumeroController,
                  label: 'Numero de registre (RCCM)',
                  hintText: 'Ex: RB/COT/20 B 12345',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir le numero RCCM.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildFilePickerTile(
                  label: 'Extrait RCCM (PDF ou Image)',
                  fileName: _rccmExtraitFileName,
                  onTap: () => _pickFile('rccm'),
                ),
                const SizedBox(height: 28),
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
