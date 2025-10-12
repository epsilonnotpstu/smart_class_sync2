import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_class_sync/screens/login_screen.dart';
import 'package:smart_class_sync/services/auth_service.dart';
import 'package:mockito/mockito.dart';

// Create a mock class for AuthService
class MockAuthService extends Mock implements AuthService {}

void main() {
  testWidgets('LoginScreen UI Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      Provider<AuthService>(
        create: (_) => MockAuthService(),
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verify that the login screen has the expected widgets.
    expect(find.text('Smart Class Sync'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and Password
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    // Enter text and try to log in
    await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password');

    // You would then mock the login call and verify navigation or error messages.
  });
}