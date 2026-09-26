import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shipaton_tienda/core/models/models.dart';
import 'package:shipaton_tienda/features/share/post_templates.dart';
import 'package:shipaton_tienda/features/share/product_stage.dart';

void main() {
  testWidgets('branded preview shows store name, title and price', (tester) async {
    const paca = Paca(
      id: '1',
      storeId: 's',
      title: 'playera polo',
      priceGtq: 10,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrandedPostTemplate(
            paca: paca,
            brandColor: Color(0xFF1B5E20),
            storeName: 'gabrieltiu5',
          ),
        ),
      ),
    );

    expect(find.text('gabrieltiu5'), findsOneWidget);
    expect(find.text('playera polo'), findsOneWidget);
    expect(find.textContaining('Q'), findsOneWidget);
    expect(find.byType(ProductStage), findsOneWidget);
    expect(find.text('VISTA PREVIA'), findsNothing);
  });

  testWidgets('free preview stamps a watermark', (tester) async {
    const paca = Paca(
      id: '1',
      storeId: 's',
      title: 'playera polo',
      priceGtq: 10,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BrandedPostTemplate(
            paca: paca,
            brandColor: Color(0xFF1B5E20),
            storeName: 'gabrieltiu5',
            showWatermark: true,
          ),
        ),
      ),
    );

    expect(find.text('VISTA PREVIA'), findsWidgets);
  });

  testWidgets('generated ad replaces the local stage', (tester) async {
    final canvas = img.Image(width: 4, height: 4, numChannels: 4);
    img.fill(canvas, color: img.ColorRgba8(20, 90, 40, 255));
    final png = Uint8List.fromList(img.encodePng(canvas));
    const paca = Paca(
      id: '1',
      storeId: 's',
      title: 'playera polo',
      priceGtq: 10,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrandedPostTemplate(
            paca: paca,
            brandColor: const Color(0xFF1B5E20),
            storeName: 'gabrieltiu5',
            generatedAdBytes: png,
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(ProductStage), findsNothing);
    expect(find.text('gabrieltiu5'), findsNothing);
    expect(find.text('playera polo'), findsNothing);
  });
}
