import 'package:flutter/material.dart';

/// Color <-> hex dönüştürme yardımcıları.
///
/// Destek:
/// - `#RRGGBB`
/// - `RRGGBB`
/// - `#AARRGGBB`
/// - `AARRGGBB`
String colorToHex(Color color) {
  final value = color.toARGB32();
  final hex = value.toRadixString(16).padLeft(8, '0').toUpperCase();
  return '#$hex';
}

Color hexToColor(String hex) {
  var cleaned = hex.trim();
  if (cleaned.isEmpty) return const Color(0x00000000);

  cleaned = cleaned.replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
  cleaned = cleaned.trim();

  if (cleaned.length == 6) {
    cleaned = 'FF$cleaned';
  }

  if (cleaned.length != 8) return const Color(0x00000000);

  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return const Color(0x00000000);

  return Color(value);
}

