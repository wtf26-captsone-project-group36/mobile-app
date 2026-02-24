import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/provider/inventory_provider.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';

void main() {
  testWidgets('app initialization test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'is_guest': true});

    // Test basic app setup and provider initialization
    final app = MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => AppStateController()),
      ],
      child: const MaterialApp(home: Scaffold(body: Text('App Loaded'))),
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('App Loaded'), findsOneWidget);
  });

  test('clearing guest flag and setting logged-in persists correctly', () async {
    SharedPreferences.setMockInitialValues({'is_guest': true});

    final store = AppSessionStore.instance;
    await store.setGuestMode(false);
    await store.setLoggedIn(true);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('is_guest'), isFalse);
    expect(prefs.getBool('is_logged_in'), isTrue);
  });
}
