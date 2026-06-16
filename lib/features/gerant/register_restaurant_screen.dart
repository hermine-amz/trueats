import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_feedback.dart';

class RegisterRestaurantScreen extends StatefulWidget {
  final Restaurant? restaurantToEdit;
  const RegisterRestaurantScreen({this.restaurantToEdit, super.key});

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
  // Champs textes pour IFU
  final _ifuNumeroController = TextEditingController();

  // Nouveaux fichiers pour CIP, Attestation IFU
  XFile? _cipFile;
  String? _cipFileName;
  XFile? _ifuAttestationFile;
  String? _ifuAttestationFileName;

  bool _isSubmitting = false;
  bool _isDetectingGps = false;

  @override
  void initState() {
    super.initState();
    if (widget.restaurantToEdit != null) {
      final r = widget.restaurantToEdit!;
      _nameController.text = r.nom;
      _addressController.text = r.adresse;
      _quartierController.text = r.quartier;
      _categoryController.text = r.categorie;
      _typeCuisineController.text = r.typeCuisine;
      _latitudeController.text = r.latitude.toString();
      _longitudeController.text = r.longitude.toString();
      _superficieController.text = (r.superficie ?? 150).toString();
      _ifuNumeroController.text = r.ifuNumero ?? '';
      
      if (r.cipUrl != null) {
        _cipFileName = r.cipUrl!.split('/').last;
      }
      if (r.ifuAttestationUrl != null) {
        _ifuAttestationFileName = r.ifuAttestationUrl!.split('/').last;
      }
    }
  }

  Future<void> _showLocationInstructionsDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.creme,
          title: const Row(
            children: [
              Icon(Icons.location_off, color: AppColors.terracotta, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Accès GPS Bloqué',
                  style: TextStyle(
                    color: AppColors.marronFonce,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'L\'accès à la position a été bloqué par votre navigateur ou votre appareil.',
                style: TextStyle(
                  color: AppColors.marronFonce,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pour réactiver l\'accès et continuer :',
                style: TextStyle(
                  color: AppColors.marronFonce,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: const Text('1. ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.terracotta)),
                  ),
                  const Expanded(
                    child: Text(
                      'Cliquez sur l\'icône de cadenas 🔒 ou de paramètres situés tout à gauche de l\'adresse de la page (URL) dans votre navigateur Chrome.',
                      style: TextStyle(color: AppColors.grisTexte, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: const Text('2. ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.terracotta)),
                  ),
                  const Expanded(
                    child: Text(
                      'Trouvez la ligne "Localisation" et réactivez-la en choisissant "Autoriser".',
                      style: TextStyle(color: AppColors.grisTexte, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: const Text('3. ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.terracotta)),
                  ),
                  const Expanded(
                    child: Text(
                      'Revenez sur cette page et cliquez à nouveau sur "Détecter ma position GPS".',
                      style: TextStyle(color: AppColors.grisTexte, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.marronFonce,
              ),
              child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _isDetectingGps = true;
    });

    try {
      final hasPermission = await ServiceLocator.locationService.requestPermission();
      if (!hasPermission) {
        final deniedForever = await ServiceLocator.locationService.isPermissionDeniedForever();
        if (!mounted) return;
        
        if (deniedForever) {
          await _showLocationInstructionsDialog();
        } else {
          showAppNotification(
            context,
            title: 'Permission requise',
            message: 'La permission d\'accès à la localisation est nécessaire pour détecter votre position.',
            type: AppFeedbackType.warning,
          );
        }
        
        setState(() {
          _isDetectingGps = false;
        });
        return;
      }

      final coords = await ServiceLocator.locationService.getCurrentLocation();
      final lat = coords['latitude'];
      final lon = coords['longitude'];

      if (lat != null && lon != null) {
        setState(() {
          _latitudeController.text = lat.toStringAsFixed(6);
          _longitudeController.text = lon.toStringAsFixed(6);
        });
        if (!mounted) return;
        showAppNotification(
          context,
          title: 'Position détectée',
          message: 'Votre position GPS a été récupérée avec succès.',
          type: AppFeedbackType.success,
        );
      } else {
        throw Exception("Coordonnées GPS incorrectes ou non renvoyées.");
      }
    } catch (e) {
      if (!mounted) return;
      showAppNotification(
        context,
        title: 'Erreur GPS',
        message: 'Impossible de détecter votre position GPS : $e',
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingGps = false;
        });
      }
    }
  }



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
    if (_cipFile == null && widget.restaurantToEdit?.cipUrl == null) {
      showAppNotification(
        context,
        title: 'Document requis',
        message: 'Le CIP du gérant est obligatoire.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    if (_ifuNumeroController.text.trim().isEmpty || (_ifuAttestationFile == null && widget.restaurantToEdit?.ifuAttestationUrl == null)) {
      showAppNotification(
        context,
        title: 'Documents requis',
        message: 'Le numéro IFU et l\'attestation IFU sont requis.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String? cipUrl = widget.restaurantToEdit?.cipUrl;
    String? ifuAttestationUrl = widget.restaurantToEdit?.ifuAttestationUrl;

    try {
      // Note de soutenance : On televerse les documents justificatifs sensibles
      // sur le serveur Laravel qui restreint l'accès aux administrateurs.
      if (_cipFile != null) {
        cipUrl = await ServiceLocator.restaurantService.uploadDocument(
          _cipFile!,
          type: 'cip',
        );
      }
      
      if (_ifuAttestationFile != null) {
        ifuAttestationUrl = await ServiceLocator.restaurantService.uploadDocument(
          _ifuAttestationFile!,
          type: 'ifu_attestation',
        );
      }
      
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

    if (widget.restaurantToEdit != null) {
      try {
        await ServiceLocator.restaurantService.updateRestaurant(
          id: widget.restaurantToEdit!.id,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          quartier: _quartierController.text.trim(),
          category: _categoryController.text.trim().isEmpty
              ? 'Restaurant'
              : _categoryController.text.trim(),
          typeCuisine: _typeCuisineController.text.trim().isEmpty
              ? 'Local'
              : _typeCuisineController.text.trim(),
          latitude: latitude,
          longitude: longitude,
          superficie: superficie,
          cipUrl: cipUrl,
          ifuNumero: _ifuNumeroController.text.trim(),
          ifuAttestationUrl: ifuAttestationUrl,
        );
        
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        Navigator.of(context).pop(true);
        showAppNotification(
          context,
          title: 'Demande resoumise',
          message: 'Les corrections ont été soumises pour validation.',
          type: AppFeedbackType.success,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        showAppNotification(
          context,
          title: 'Erreur de mise à jour',
          message: 'Erreur modification restaurant : $e',
          type: AppFeedbackType.error,
        );
      }
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
      rccmNumero: null,
      rccmExtraitUrl: null,
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
        title: Text(widget.restaurantToEdit != null ? 'Modifier restaurant' : 'Inscription restaurant'),
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
                  widget.restaurantToEdit != null ? 'Corriger le restaurant' : 'Inscrire un nouveau restaurant',
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
                  readOnly: false, // Option B : Le nom est modifiable et repassera en validation si changé
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
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.grisBordure),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.terracotta),
                          const SizedBox(width: 8),
                          Text(
                            'Localisation du restaurant',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.marronFonce,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pour enregistrer votre établissement, vous devez être physiquement présent dans le restaurant et détecter votre position GPS en temps réel.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Détection GPS — l'utilisateur doit être dans le restaurant
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isDetectingGps ? null : _detectCurrentLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.terracotta,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _isDetectingGps
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location, size: 18),
                          label: Text(
                            _isDetectingGps ? 'Détection en cours...' : 'Détecter ma position GPS',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.grisBordure, height: 1),
                      const SizedBox(height: 16),

                      // Affichage des coordonnées GPS enregistrées (ReadOnly)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latitudeController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Latitude détectée',
                                filled: true,
                                fillColor: AppColors.cremeFonce.withValues(alpha: 0.4),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.grisBordure),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.grisBordure),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Appuyez sur le bouton GPS';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _longitudeController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Longitude détectée',
                                filled: true,
                                fillColor: AppColors.cremeFonce.withValues(alpha: 0.4),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.grisBordure),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.grisBordure),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Appuyez sur le bouton GPS';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                      : Text(widget.restaurantToEdit != null ? 'Modifier et resoumettre' : 'Inscrire le restaurant'),
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
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      readOnly: readOnly,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: readOnly ? AppColors.cremeFonce.withValues(alpha: 0.4) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.grisBordure),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.grisBordure),
        ),
      ),
    );
  }
}
