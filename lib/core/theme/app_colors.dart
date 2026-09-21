import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF3B82F6);
  static const primaryDark = Color(0xFF2563EB);
  static const primaryLight = Color(0xFF60A5FA);
  static const cyan = Color(0xFF22D3EE);

  // Dark theme
  static const darkBackground = Color(0xFF0B1B33);
  static const darkSurface = Color(0xFF102542);
  static const darkSurfaceElevated = Color(0xFF163052);
  static const darkBorder = Color(0xFF24466F);

  // Light theme
  static const lightBackground = Color(0xFFF7FAFF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceElevated = Color(0xFFF0F6FF);
  static const lightBorder = Color(0xFFDCE8F7);

  // Text
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const textDark = Color(0xFF0F172A);
  static const textDarkSecondary = Color(0xFF64748B);

  // Status
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}