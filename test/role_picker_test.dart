import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shipaton_tienda/features/auth/role_picker_screen.dart';

void main() {
  testWidgets('RolePicker shows store and buyer options', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RolePickerScreen()),
      ),
    );

    expect(find.text('Soy tienda'), findsOneWidget);
    expect(find.text('Soy comprador'), findsOneWidget);
  });
}
