import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/route_planning/presentation/route_soc_colour.dart';

// Colour mapping for FR-ROUTE-006 / ADR-0023.
void main() {
  Color colourAt(double soc) => Color(socColourArgb(soc, reservePercent: 10));

  test('is green at or above 60 percent', () {
    expect(colourAt(80), colourAt(60));
    expect(colourAt(100), const Color(0xFF2E7D32));
  });

  test('reaches red at the reserve and dark red below it', () {
    expect(colourAt(10), const Color(0xFFD32F2F));
    expect(colourAt(4), const Color(0xFF7F0000));
    expect(colourAt(0), const Color(0xFF7F0000));
  });

  test('runs green -> yellow -> red as the charge drops', () {
    final high = colourAt(55);
    final mid = colourAt(35);
    final low = colourAt(18);
    // Red channel rises and green channel falls as the charge drops.
    expect(mid.r, greaterThan(high.r));
    expect(low.g, lessThan(mid.g));
  });
}
