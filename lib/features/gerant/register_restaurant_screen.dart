import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/benin_locations.dart';

class DayHours {
  bool isOpen;
  String openTime;
  String closeTime;

  DayHours({this.isOpen = true, this.openTime = '08h00', this.closeTime = '22h00'});
}

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
  final _telephoneController = TextEditingController();
  final _horairesController = TextEditingController();
  final _quartierController = TextEditingController();
  String _selectedRestaurantCategory = 'Maquis';
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

  late String _selectedVille;
  late String _selectedQuartier;
  late List<String> _currentQuartiers;

  late Map<String, DayHours> _daysHours;
  final List<String> _timeOptions = [
    '00h00', '00h30', '01h00', '01h30', '02h00', '02h30', '03h00', '03h30',
    '04h00', '04h30', '05h00', '05h30', '06h00', '06h30', '07h00', '07h30',
    '08h00', '08h30', '09h00', '09h30', '10h00', '10h30', '11h00', '11h30',
    '12h00', '12h30', '13h00', '13h30', '14h00', '14h30', '15h00', '15h30',
    '16h00', '16h30', '17h00', '17h30', '18h00', '18h30', '19h00', '19h30',
    '20h00', '20h30', '21h00', '21h30', '22h00', '22h30', '23h00', '23h30'
  ];

  void _parseQuartierAndVille(String dbQuartier) {
    if (dbQuartier.contains(',')) {
      final parts = dbQuartier.split(',');
      final qPart = parts[0].trim();
      final vPart = parts[1].trim();
      if (beninLocations.containsKey(vPart)) {
        _selectedVille = vPart;
        _currentQuartiers = List.from(beninLocations[_selectedVille]!);
        _selectedQuartier = qPart;
        if (!_currentQuartiers.contains(_selectedQuartier)) {
          _currentQuartiers.add(_selectedQuartier);
        }
        return;
      }
    }
    
    for (final city in beninLocations.keys) {
      if (dbQuartier.toLowerCase().contains(city.toLowerCase())) {
        _selectedVille = city;
        _currentQuartiers = List.from(beninLocations[_selectedVille]!);
        final cleanQ = dbQuartier.replaceAll(RegExp(city, caseSensitive: false), '').replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
        _selectedQuartier = cleanQ.isNotEmpty ? cleanQ : _currentQuartiers.first;
        if (!_currentQuartiers.contains(_selectedQuartier)) {
          _currentQuartiers.add(_selectedQuartier);
        }
        return;
      }
    }

    _selectedVille = 'Cotonou';
    _currentQuartiers = List.from(beninLocations[_selectedVille]!);
    if (dbQuartier.isNotEmpty) {
      _selectedQuartier = dbQuartier;
      if (!_currentQuartiers.contains(_selectedQuartier)) {
        _currentQuartiers.add(_selectedQuartier);
      }
    } else {
      _selectedQuartier = _currentQuartiers.first;
    }
  }

  @override
  void initState() {
    super.initState();
    _daysHours = {
      'Lundi': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
      'Mardi': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
      'Mercredi': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
      'Jeudi': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
      'Vendredi': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
      'Samedi': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
      'Dimanche': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
    };
    _updateHorairesController();

    _selectedVille = 'Cotonou';
    _currentQuartiers = List.from(beninLocations[_selectedVille]!);
    _selectedQuartier = _currentQuartiers.contains('Haie Vive') ? 'Haie Vive' : _currentQuartiers.first;

    if (widget.restaurantToEdit != null) {
      final r = widget.restaurantToEdit!;
      _nameController.text = r.nom;
      _addressController.text = r.adresse;
      String initialPhone = r.telephone ?? '';
      if (initialPhone.startsWith("+229")) {
        initialPhone = initialPhone.substring(4).trim();
      }
      _telephoneController.text = initialPhone;
      
      _daysHours = _parseHoraires(r.horaires);
      _updateHorairesController();
      
      final dbQuartier = r.quartier;
      _parseQuartierAndVille(dbQuartier);
      _quartierController.text = dbQuartier.isNotEmpty ? dbQuartier : '$_selectedQuartier, $_selectedVille';
      _selectedRestaurantCategory = kRestaurantCategories.contains(r.categorie)
          ? r.categorie
          : kRestaurantCategories.first;
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
    _telephoneController.dispose();
    _horairesController.dispose();
    _quartierController.dispose();
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

    final tel = _telephoneController.text.trim().replaceAll(' ', '');
    final telephoneComplet = tel.isNotEmpty ? '+229$tel' : null;

    if (widget.restaurantToEdit != null) {
      try {
        await ServiceLocator.restaurantService.updateRestaurant(
          id: widget.restaurantToEdit!.id,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          telephone: telephoneComplet,
          horaires: _horairesController.text.trim().isEmpty ? null : _horairesController.text.trim(),
          quartier: _quartierController.text.trim(),
          category: _selectedRestaurantCategory,
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
      telephone: telephoneComplet,
      horaires: _horairesController.text.trim().isEmpty ? null : _horairesController.text.trim(),
      quartier: _quartierController.text.trim(),
      categorie: _selectedRestaurantCategory,
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
                TextFormField(
                  controller: _addressController,
                  maxLines: 4,
                  minLines: 2,
                  decoration: InputDecoration(
                    labelText: "Itinéraire",
                    hintText: "Décrivez le chemin pour aller...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.grisBordure),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.grisBordure),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Veuillez décrire l'itinéraire pour aller au restaurant.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Téléphone",
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
                const SizedBox(height: 16),
                _buildHoursSelectionSection(context),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedVille,
                        items: beninLocations.keys.map((ville) {
                          return DropdownMenuItem<String>(
                            value: ville,
                            child: Text(ville, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedVille = val;
                              _currentQuartiers = List.from(beninLocations[_selectedVille]!);
                              _selectedQuartier = _currentQuartiers.first;
                              _quartierController.text = '$_selectedQuartier, $_selectedVille';
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Ville',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.grisBordure),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.grisBordure),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_selectedVille),
                        initialValue: _selectedQuartier,
                        items: _currentQuartiers.map((quartier) {
                          return DropdownMenuItem<String>(
                            value: quartier,
                            child: Text(quartier, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedQuartier = val;
                              _quartierController.text = '$_selectedQuartier, $_selectedVille';
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Quartier',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.grisBordure),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.grisBordure),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setDropState) {
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedRestaurantCategory,
                      decoration: InputDecoration(
                        labelText: 'Catégorie',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.grisBordure),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.grisBordure),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.terracotta, width: 2),
                        ),
                      ),
                      items: kRestaurantCategories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: _isSubmitting ? null : (val) {
                        if (val != null) {
                          setState(() => _selectedRestaurantCategory = val);
                        }
                      },
                    );
                  },
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

  Widget _buildHoursSelectionSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Horaires d'ouverture par jour",
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.marronFonce,
          ),
        ),
        const SizedBox(height: 12),
        ..._daysHours.entries.map((entry) {
          final day = entry.key;
          final dh = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 85,
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.marronFonce,
                      fontSize: 13,
                    ),
                  ),
                ),
                Switch(
                  value: dh.isOpen,
                  activeThumbColor: AppColors.terracotta,
                  onChanged: (val) {
                    setState(() {
                      dh.isOpen = val;
                      _updateHorairesController();
                    });
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: dh.isOpen
                      ? Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: DropdownButtonFormField<String>(
                                  initialValue: dh.openTime,
                                  items: _timeOptions.map((time) {
                                    return DropdownMenuItem<String>(
                                      value: time,
                                      child: Text(time, style: const TextStyle(fontSize: 11)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        dh.openTime = val;
                                        _updateHorairesController();
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    labelText: 'Ouv',
                                    labelStyle: const TextStyle(fontSize: 9),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.grisBordure),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.grisBordure),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text('à', style: TextStyle(fontSize: 11)),
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: DropdownButtonFormField<String>(
                                  initialValue: dh.closeTime,
                                  items: _timeOptions.map((time) {
                                    return DropdownMenuItem<String>(
                                      value: time,
                                      child: Text(time, style: const TextStyle(fontSize: 11)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        dh.closeTime = val;
                                        _updateHorairesController();
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                    labelText: 'Ferm',
                                    labelStyle: const TextStyle(fontSize: 9),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.grisBordure),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.grisBordure),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Fermé',
                          style: TextStyle(
                            color: AppColors.rougeSignalement,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _updateHorairesController() {
    _horairesController.text = _formatHoraires(_daysHours);
  }

  String _formatHoraires(Map<String, DayHours> daysHours) {
    final List<String> parts = [];
    daysHours.forEach((day, dh) {
      if (dh.isOpen) {
        parts.add('$day : ${dh.openTime} - ${dh.closeTime}');
      } else {
        parts.add('$day : Fermé');
      }
    });
    return parts.join('\n');
  }

  Map<String, DayHours> _parseHoraires(String? horairesStr) {
    final Map<String, DayHours> result = {
      'Lundi': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
      'Mardi': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
      'Mercredi': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
      'Jeudi': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
      'Vendredi': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
      'Samedi': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
      'Dimanche': DayHours(openTime: '08h00', closeTime: '22h00', isOpen: true),
    };

    if (horairesStr == null || horairesStr.trim().isEmpty) {
      return result;
    }

    if (!horairesStr.contains('Lundi') && !horairesStr.contains('Mardi') && horairesStr.contains('-')) {
      final parts = horairesStr.split('-');
      if (parts.length == 2) {
        final start = parts[0].trim();
        final end = parts[1].trim();
        if (_timeOptions.contains(start) && _timeOptions.contains(end)) {
          for (final day in result.keys) {
            result[day] = DayHours(openTime: start, closeTime: end, isOpen: true);
          }
        }
      }
      return result;
    }

    final lines = horairesStr.split(RegExp(r'[\n,|]'));
    for (final line in lines) {
      final trimmedLine = line.trim();
      for (final day in result.keys) {
        if (trimmedLine.toLowerCase().startsWith(day.toLowerCase())) {
          if (trimmedLine.toLowerCase().contains('fermé') || trimmedLine.toLowerCase().contains('ferme')) {
            result[day] = DayHours(openTime: '08h00', closeTime: '22h00', isOpen: false);
          } else if (trimmedLine.contains('-')) {
            final timePart = trimmedLine.split(':').skip(1).join(':').trim();
            final times = timePart.split('-');
            if (times.length == 2) {
              final start = times[0].trim();
              final end = times[1].trim();
              if (_timeOptions.contains(start) && _timeOptions.contains(end)) {
                result[day] = DayHours(openTime: start, closeTime: end, isOpen: true);
              }
            }
          }
        }
      }
    }

    return result;
  }
}
