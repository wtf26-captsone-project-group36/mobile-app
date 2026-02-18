import 'package:flutter/material.dart';
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
}
