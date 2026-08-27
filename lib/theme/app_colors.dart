import 'package:flutter/material.dart';

/// Each major section ("menu") of the app gets its own accent color so the
/// interface feels distinct as you move between them, while every screen
/// still shares the same card/spacing/typography language for consistency.
///
/// Usage: use `AppColors.<section>` for that section's AppBar background,
/// FloatingActionButton, and primary buttons.
class AppColors {
  AppColors._();

  /// Login / Signup / Forgot Password — the app's core brand color.
  static const Color auth = Color(0xFF00796B); // teal 700

  /// Dashboard / Home tab.
  static const Color dashboard = Color(0xFF00695C); // teal 800
  static const List<Color> dashboardGradient = [
    Color(0xFF00695C),
    Color(0xFF26A69A),
  ];

  /// Medicines tab (inventory list, add/edit medicine, bulk upload).
  static const Color medicines = Color(0xFF3949AB); // indigo 600

  /// Medicine Reference (browsable drug-info database).
  static const Color reference = Color(0xFF2E7D32); // green 800

  /// Medicine & Patient Lookup.
  static const Color lookup = Color(0xFF00838F); // cyan 800

  /// Sell tab (point of sale, sales history).
  static const Color sell = Color(0xFFE64A19); // deep orange 700

  /// Patients tab (patient list, add patient, patient history).
  static const Color patients = Color(0xFF6A1B9A); // purple 800

  /// Alerts tab (low stock / expiring / expired).
  static const Color alerts = Color(0xFFC62828); // red 800

  /// Settings.
  static const Color settings = Color(0xFF37474F); // blue grey 800
}
