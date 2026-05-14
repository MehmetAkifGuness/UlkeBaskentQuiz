import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunya_ulkeleri_flutter/widgets/geo_bottom_nav.dart';

void main() {
  testWidgets('GeoBottomNav renders and calls onChanged', (tester) async {
    int? tappedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: GeoBottomNav(
            currentIndex: 0,
            items: const [
              GeoNavItem(icon: Icons.home_rounded, label: 'Anasayfa'),
              GeoNavItem(icon: Icons.public_rounded, label: 'Harita'),
            ],
            onChanged: (i) => tappedIndex = i,
          ),
        ),
      ),
    );

    expect(find.text('Anasayfa'), findsOneWidget);
    expect(find.text('Harita'), findsOneWidget);

    await tester.tap(find.text('Harita'));
    await tester.pumpAndSettle();

    expect(tappedIndex, 1);
  });
}
