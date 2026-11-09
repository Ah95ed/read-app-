import 'package:flutter/material.dart';

/// Application color definitions and reading palettes
class AppColors {
  AppColors._();

  // Primary brand palette (Deep elegant Navy / Emerald for reading)
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF172554);
  static const Color accent = Color(0xFF0284C7);

  // Surface colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightAppBar = Colors.white;

  // Dark mode colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkAppBar = Color(0xFF1E293B);

  // Sepia eye-care mode colors
  static const Color sepiaBackground = Color(0xFFFBF0D9);
  static const Color sepiaSurface = Color(0xFFF4ECD8);
  static const Color sepiaText = Color(0xFF5F4B32);

  // Status and accents
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color darkDivider = Color(0xFF334155);
}

