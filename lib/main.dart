import 'package:flutter/material.dart';
import 'package:hervest_ai/core/network/auth_api_service.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart'; // Handles Search, Profile, & Finance
import 'package:hervest_ai/core/network/api_health_service.dart';
import 'package:hervest_ai/core/network/api_config.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';

import 'package:provider/provider.dart';
import 'package:hervest_ai/router/app_router.dart';

// Import your Providers/Logic Controllers
import 'package:hervest_ai/provider/inventory_provider.dart';
import 'package:hervest_ai/provider/profile_controller.dart';
import 'package:hervest_ai/provider/rescue_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrapAuthSession();
  _logApiHealth();

  runApp(
    MultiProvider(
      providers: [
        // Manages the Inventory Ledger & AI Suggestion Logic
        ChangeNotifierProvider(create: (_) => InventoryProvider()),

        // Manages Global Search, User Profile, & Cashflow Data
        ChangeNotifierProvider(create: (_) => AppStateController()),

        // Manages Profile data (name, contact, business, avatar)
        ChangeNotifierProvider(create: (_) => ProfileController()..load()),
        ChangeNotifierProxyProvider<InventoryProvider, RescueProvider>(
          create: (_) {
            final rescue = RescueProvider();
            rescue.initialize();
            return rescue;
          },
          update: (_, inventory, rescue) {
            final active = rescue ?? RescueProvider();
            active.syncInventory(inventory.items);
            return active;
          },
        ),
      ],
      child: const SurplusApp(),
    ),
  );
}

Future<void> _bootstrapAuthSession() async {
  final store = AppSessionStore.instance;
  final refreshToken = await store.getRefreshToken();
  final accessToken = await store.getAccessToken();

  if ((refreshToken == null || refreshToken.isEmpty) &&
      (accessToken == null || accessToken.isEmpty)) {
    return;
  }

  if (refreshToken == null || refreshToken.isEmpty) return;

  try {
    const authApi = AuthApiService();
    final session = await authApi.refreshSession(refreshToken: refreshToken);
    if (session.accessToken.isNotEmpty && session.refreshToken.isNotEmpty) {
      await store.setAuthTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      await store.setLoggedIn(true);
      await store.setGuestMode(false);
    }
  } catch (_) {
    await store.clearAuthTokens();
    await store.setLoggedIn(false);
  }
}

void _logApiHealth() {
  const healthService = ApiHealthService();
  healthService.check().then((result) {
    if (result.ok) {
      debugPrint(
        '[API] Healthy at ${result.endpointTried} (base: ${ApiConfig.baseUrl})',
      );
    } else {
      debugPrint(
        '[API] Unhealthy at ${result.endpointTried} '
        '(status: ${result.statusCode}, error: ${result.error}) '
        '(base: ${ApiConfig.baseUrl})',
      );
    }
  });
}

class SurplusApp extends StatelessWidget {
  const SurplusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'HerVest AI',
      theme: ThemeData(
        useMaterial3: true,
        // Branding Palette matches your screenshots
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006B4D), // Deep Green
          primary: const Color(0xFF006B4D),
        ),
        scaffoldBackgroundColor: const Color(0xFFFDFBF7), // Cream
        // Clean text theme for a "classy" look
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(color: Colors.black54),
        ),

        // Global styling for switches (used in your Notification settings)
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFF006B4D)
                : null,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFF006B4D).withValues(alpha: 0.5)
                : null,
          ),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:hervest_ai/router/app_router.dart';
// Import your new logic files
import 'package:hervest_ai/provider/inventory_provider.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    // MultiProvider allows for the adding of more providers later (FinanceProvider...)
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
      ],
      child: const SurplusApp(),
    ),
  );
}

class SurplusApp extends StatelessWidget {
  const SurplusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'HerVest AI',
      theme: ThemeData(
        useMaterial3: true,
        // Using your professional Cream background as the default scaffold color
        colorSchemeSeed: const Color(0xFF006B4D), // Deep Green from your mockups
        scaffoldBackgroundColor: const Color(0xFFFDFBF7), // Cream
      ),
      routerConfig: appRouter,
    );
  }
}  */

/*import 'package:flutter/material.dart';
import 'package:hervest_ai/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SurplusApp());
}

class SurplusApp extends StatelessWidget {
  const SurplusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'HerVest AI',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      routerConfig: appRouter,
    );
  }
}*/
