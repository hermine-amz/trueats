import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Palette principale de la DA TruEats
  static const Color terracotta = Color(0xFFC0552D);
  static const Color sauge = Color(0xFF75B58D);
  static const Color creme = Color(0xFFFAF6EE);
  static const Color marronFonce = Color(0xFF2E1E17);
  
  // Couleurs secondaires et fonctionnelles
  static const Color grisBordure = Color(0xFFE5E0D8);
  static const Color cremeFonce = Color(0xFFF3ECE0);
  static const Color vertClair = Color(0xFFE2F0E7);
  static const Color rougeClair = Color(0xFFFFEBEE);
  static const Color rougeSignalement = Color(0xFFC62828);
  static const Color grisTexte = Color(0xFF7A6F68);
  static const Color orangeClair = Color(0xFFFBE9E7);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.outfitTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.creme,
      primaryColor: AppColors.terracotta,
      colorScheme: const ColorScheme.light(
        primary: AppColors.terracotta,
        secondary: AppColors.sauge,
        surface: AppColors.creme,
        onSurface: AppColors.marronFonce,
        error: AppColors.rougeSignalement,
      ),
      
      // Configuration de la typographie globale
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.lora(
          color: AppColors.marronFonce,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        displayMedium: GoogleFonts.lora(
          color: AppColors.marronFonce,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        displaySmall: GoogleFonts.lora(
          color: AppColors.marronFonce,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        titleLarge: GoogleFonts.outfit(
          color: AppColors.marronFonce,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: AppColors.marronFonce,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: AppColors.grisTexte,
          fontSize: 14,
        ),
        labelLarge: GoogleFonts.outfit(
          color: AppColors.marronFonce,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      
      // Style des champs de saisie (Inputs style pilule)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFDFBF7),
        hintStyle: GoogleFonts.outfit(
          color: AppColors.grisTexte.withAlpha(150),
          fontSize: 15,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.grisBordure),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.grisBordure),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.terracotta, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.rougeSignalement),
        ),
        prefixIconColor: AppColors.grisTexte,
        suffixIconColor: AppColors.grisTexte,
      ),
      
      // Style des boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.marronFonce,
          side: const BorderSide(color: AppColors.grisBordure, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // Style de l'AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.lora(
          color: AppColors.marronFonce,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.marronFonce),
      ),
    );
  }
}
