import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// IMPORTANT: Replace 'roamie' with your actual project name if it differs.
import 'package:roamie/main.dart';

void main() {
  testWidgets('Roamie Home Screen loads UI elements correctly', (WidgetTester tester) async {
    // 1. Build our app and trigger a frame.
    await tester.pumpWidget(const RoamieApp());

    // 2. Verify Header Section
    // Check for the main app title
    expect(find.text('ROAMIE'), findsOneWidget);
    // Check for the subtitle
    expect(find.text('Your AI Travel Companion'), findsOneWidget);
    // Check for the floating plane icon
    expect(find.byIcon(Icons.flight), findsOneWidget);

    // 3. Verify Features Grid
    expect(find.text('Features'), findsOneWidget);
    
    // Check if the specific feature titles are present
    expect(find.text('Plan Your Trip'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);
    expect(find.text('Budget Tracker'), findsOneWidget);
    expect(find.text('Interactive Map'), findsOneWidget);

    // 4. Verify Quick Actions Section
    expect(find.text('Quick Start'), findsOneWidget);
    expect(find.text('Start Planning Your Trip'), findsOneWidget);

    // 5. Verify Icons
    // 'location_on' is used in the "Plan Your Trip" card AND the "Quick Start" button
    expect(find.byIcon(Icons.location_on), findsAtLeastNWidgets(2)); 
    // 'translate' icon check
    expect(find.byIcon(Icons.translate), findsOneWidget);
  });
  
  testWidgets('Quick Start button is tappable', (WidgetTester tester) async {
    await tester.pumpWidget(const RoamieApp());

    // Find the button by text
    final buttonFinder = find.text('Start Planning Your Trip');
    
    // Ensure it is visible
    await tester.ensureVisible(buttonFinder);
    
    // Tap it
    await tester.tap(buttonFinder);
    
    // Rebuild the widget after the state has changed.
    await tester.pump();

    // Since our button currently just prints to console, we are mostly testing 
    // that the tap doesn't crash the app here.
    expect(buttonFinder, findsOneWidget);
  });
}