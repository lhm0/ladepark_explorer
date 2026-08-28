import 'package:flutter/material.dart';

const _green = Color(0xFF2E7D32);
const _yellow = Color(0xFFF9A825);
const _red = Color(0xFFD32F2F);
const _darkRed = Color(0xFF7F0000);

/// Maps an estimated state of charge in percent to a route line colour
/// (ADR-0023): green at or above 60 %, yellow at 35 %, red at the reserve,
/// a clearly darker red below the reserve.
int socColourArgb(double socPercent, {required int reservePercent}) {
  final reserve = reservePercent.toDouble();
  if (socPercent >= 60) return _green.toARGB32();
  if (socPercent < reserve) return _darkRed.toARGB32();
  if (socPercent <= reserve) return _red.toARGB32();
  if (socPercent >= 35) {
    final t = ((60 - socPercent) / (60 - 35)).clamp(0.0, 1.0);
    return Color.lerp(_green, _yellow, t)!.toARGB32();
  }
  final span = 35 - reserve;
  final t = span <= 0 ? 1.0 : ((35 - socPercent) / span).clamp(0.0, 1.0);
  return Color.lerp(_yellow, _red, t)!.toARGB32();
}
