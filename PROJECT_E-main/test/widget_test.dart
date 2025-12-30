import 'package:flutter_test/flutter_test.dart';
import 'package:nomaden_app/main.dart';

void main() {
  testWidgets('App loads and shows role chooser screen',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the role chooser screen is displayed.
    expect(find.text('Pilih Role'), findsOneWidget);
    expect(find.text('Silakan pilih peran Anda:'), findsOneWidget);
    expect(find.text('Saya Client'), findsOneWidget);
    expect(find.text('Saya Driver'), findsOneWidget);
  });

  testWidgets('Navigate to next screen after choosing Client Role',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap the "Saya Client" button
    final clientButton = find.text('Saya Client');
    expect(clientButton, findsOneWidget);
    await tester.tap(clientButton);
    await tester.pumpAndSettle();

    // Verify navigation to the next screen, for example SplashScreen or LoginScreen depending on navigation.
    // Let's assume splash screen displays 'Memuat...' text or similar, adjust as per actual implementation.
    expect(find.textContaining('Memuat'), findsOneWidget);
  });

  testWidgets('Navigate to next screen after choosing Driver Role',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap the "Saya Driver" button
    final driverButton = find.text('Saya Driver');
    expect(driverButton, findsOneWidget);
    await tester.tap(driverButton);
    await tester.pumpAndSettle();

    // Verify navigation to the next screen, for example SplashScreen or LoginScreen depending on navigation.
    expect(find.textContaining('Memuat'), findsOneWidget);
  });
}
