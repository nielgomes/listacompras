// Basic Flutter widget test for Lista de Compras app.
//
// Tests the main app structure and home page rendering.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listacompras2/main.dart';

void main() {
  testWidgets('App loads and displays home page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app bar title is displayed
    expect(find.text('Lista de Compras'), findsOneWidget);
    
    // Verify that the floating action button exists (for adding items)
    expect(find.byIcon(Icons.add), findsWidgets);
    
    // Verify that the app bar actions are present
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });
}
