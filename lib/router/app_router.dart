import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// --- MODELS ---
import 'package:hervest_ai/models/inventory_model.dart';

// --- ONBOARDING & AUTH ---
import 'package:hervest_ai/features/onboarding/splash_screen.dart';
import 'package:hervest_ai/pages/landing_page.dart';
import 'package:hervest_ai/pages/signin_page.dart';
import 'package:hervest_ai/pages/signup_page.dart';

// --- CORE DASHBOARD, SEARCH & PROFILE ---
import 'package:hervest_ai/pages/dashboard_page.dart';
import 'package:hervest_ai/bottom_navigation/search/global_search_overlay.dart';
import 'package:hervest_ai/bottom_navigation/profile_screen.dart'; // The new integrated Profile/Notification page

// --- INVENTORY FLOW ---
import 'package:hervest_ai/bottom_navigation/inventory_screen.dart';
import 'package:hervest_ai/bottom_navigation/inventory_page_two.dart';
import 'package:hervest_ai/bottom_navigation/inventory_page_three.dart';
import 'package:hervest_ai/bottom_navigation/inventory_page_four.dart';

// --- AI & IMPACT FLOW ---
import 'package:hervest_ai/bottom_navigation/suggestions_screen.dart';
import 'package:hervest_ai/bottom_navigation/suggestions_logistics_page.dart';
import 'package:hervest_ai/bottom_navigation/sugg_impact_dashboard_page.dart';

// --- CASHFLOW FLOW ---
import 'package:hervest_ai/bottom_navigation/cashflow_screen.dart';
import 'package:hervest_ai/bottom_navigation/cashflow_addexpense_page.dart';
import 'package:hervest_ai/bottom_navigation/cashflow_addincome_page.dart';
import 'package:hervest_ai/bottom_navigation/cashflow_transactionhistory_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // --- Initial Entry ---
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/landing', builder: (context, state) => const LandingPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),

    // --- Main Dashboard & Search ---
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => const MaterialPage(
        fullscreenDialog: true, 
        child: GlobalSearchPage(),
      ),
    ),

    // --- Profile & Notification (Integrated) ---
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),

    // --- Inventory Flow ---
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const InventoryPageOne(),
      routes: [
        GoRoute(path: 'add', builder: (context, state) => const InventoryPageTwo()),
        GoRoute(path: 'review', builder: (context, state) => const InventoryPageThree()),
        GoRoute(path: 'success', builder: (context, state) => const InventoryPageFour()),
      ],
    ),

    // --- AI Suggestions & Impact ---
    GoRoute(
      path: '/suggestions',
      builder: (context, state) => const SuggestionsScreen(),
    ),
    GoRoute(
      path: '/suggestion-logistics',
      builder: (context, state) {
        final Map<String, dynamic> extras = state.extra as Map<String, dynamic>;
        return SuggestionsLogisticsPage(
          item: extras['item'] as InventoryItem,
          suggestedDonee: extras['donee'] as String,
        );
      },
    ),
    GoRoute(
      path: '/impact-stats',
      builder: (context, state) => const ImpactDashboardPage(),
    ),

    // --- Cashflow Flow ---
    GoRoute(
      path: '/cashflow',
      builder: (context, state) => const CashflowScreen(),
      routes: [
        GoRoute(path: 'add-expense', builder: (context, state) => const AddExpensePage()),
        GoRoute(path: 'add-income', builder: (context, state) => const AddIncomePage()),
      ],
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionHistoryPage(),
    ),
  ],
);





/*import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/bottom_navigation/cashflow_addexpense_page.dart';
import 'package:hervest_ai/bottom_navigation/cashflow_addincome_page.dart';
import 'package:hervest_ai/bottom_navigation/cashflow_screen.dart';
import 'package:hervest_ai/bottom_navigation/cashflow_transactionhistory_page.dart';
import 'package:hervest_ai/bottom_navigation/search/global_search_overlay.dart';
import 'package:hervest_ai/bottom_navigation/sugg_impact_dashboard_page.dart';
import 'package:hervest_ai/bottom_navigation/suggestions_logistics_page.dart';
import 'package:hervest_ai/bottom_navigation/suggestions_screen.dart';

// --- MODELS ---
import 'package:hervest_ai/models/inventory_model.dart';

// --- ONBOARDING & AUTH ---
import 'package:hervest_ai/features/onboarding/splash_screen.dart';
import 'package:hervest_ai/pages/dashboard_page.dart';
import 'package:hervest_ai/pages/landing_page.dart';
import 'package:hervest_ai/pages/signin_page.dart';
import 'package:hervest_ai/pages/signup_page.dart';

// --- CORE DASHBOARD & SEARCH --- dashboard, global search


// --- INVENTORY FLOW (Pages 1-4) --- main list, add item, review, success
import 'package:hervest_ai/bottom_navigation/inventory_screen.dart';
import 'package:hervest_ai/bottom_navigation/inventory_page_two.dart';
import 'package:hervest_ai/bottom_navigation/inventory_page_three.dart';
import 'package:hervest_ai/bottom_navigation/inventory_page_four.dart';

// --- AI & IMPACT FLOW (Pages 5-7) --- suggestions list, logistics details, impact dashboard


// --- CASHFLOW FLOW (Pages 8-11) --- screen, add expense, add income, transaction history


final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // --- Initial Entry ---
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/landing', builder: (context, state) => const LandingPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),

    // --- Main Dashboard & Search ---
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const GlobalSearchPage(),
    ),

    // --- Inventory Flow ---
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const InventoryPageOne(),
      routes: [
        GoRoute(path: 'add', builder: (context, state) => const InventoryPageTwo()),
        GoRoute(path: 'review', builder: (context, state) => const InventoryPageThree()),
        GoRoute(path: 'success', builder: (context, state) => const InventoryPageFour()),
      ],
    ),

    // --- AI Suggestions & Impact ---
    GoRoute(
      path: '/suggestions',
      builder: (context, state) => const SuggestionsScreen(),
    ),
    GoRoute(
      path: '/suggestion-logistics',
      builder: (context, state) {
        final Map<String, dynamic> extras = state.extra as Map<String, dynamic>;
        return SuggestionsLogisticsPage(
          item: extras['item'] as InventoryItem,
          suggestedDonee: extras['donee'] as String,
        );
      },
    ),
    GoRoute(
      path: '/impact-stats',
      builder: (context, state) => const ImpactDashboardPage(),
    ),

    // --- Cashflow Flow ---
    GoRoute(
      path: '/cashflow',
      builder: (context, state) => const CashflowScreen(),
      routes: [
        GoRoute(path: 'add-expense', builder: (context, state) => const AddExpensePage()),
        GoRoute(path: 'add-income', builder: (context, state) => const AddIncomePage()),
      ],
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionHistoryPage(),
    ),
  ],
); */






/*import 'package:go_router/go_router.dart';
import 'package:hervest_ai/bottom_navigation/bottom_navigation.dart';
import 'package:hervest_ai/bottom_navigation/sugg_impact_dashboard_page.dart';  //7
import 'package:hervest_ai/bottom_navigation/suggestions_logistics_page.dart';  //6
import 'package:hervest_ai/bottom_navigation/suggestions_screen.dart';         //5
import 'package:hervest_ai/bottom_navigation/suggestions_success_page.dart';    //6

import 'package:hervest_ai/bottom_navigation/suggestions_success_page.dart'; //6 at success state
import 'package:hervest_ai/features/onboarding/splash_screen.dart';
import 'package:hervest_ai/models/inventory_model.dart';
// Import your new pages here
import 'package:hervest_ai/bottom_navigation/inventory_screen.dart'; // Page 1
import 'package:hervest_ai/bottom_navigation/inventory_page_two.dart'; // Page 2
import 'package:hervest_ai/bottom_navigation/inventory_page_three.dart'; // Page 3
import 'package:hervest_ai/bottom_navigation/inventory_page_four.dart'; // Page 4

// ... other imports (Auth, Onboarding, etc.)

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

    /* ... Onboarding & Auth Routes (Keep as is) ... */

    // Dashboard (Main Navigation)
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MainNavigationScreen(),
    ),

    // --- INVENTORY LEDGER FLOW (Pages 1-4) ---
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const InventoryPageOne(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const InventoryPageTwo(),
        ),
        GoRoute(
          path: 'review',
          builder: (context, state) => const InventoryPageThree(),
        ),
        GoRoute(
          path: 'success',
          builder: (context, state) => const InventoryPageFour(),
        ),
      ],
    ),

    // --- AI SUGGESTION & IMPACT FLOW (Pages 5-7) ---
    
    // Page 5: The AI Suggestion List
    GoRoute(
      path: '/suggestions',
      builder: (context, state) => const SuggestionsScreen(),
    ),

    // Page 6: Suggestion Logistics (Passes item data via extra)
    GoRoute(
      path: '/suggestion-logistics',
      builder: (context, state) {
        final Map<String, dynamic> extras = state.extra as Map<String, dynamic>;
        return SuggestionsLogisticsPage(
          item: extras['item'] as InventoryItem,
          suggestedDonee: extras['donee'] as String,
        );
      },
    ),

    // Page 6.5: Handshake Success
    GoRoute(
      path: '/suggestion-success',
      builder: (context, state) => const SuggestionSuccessPage(),
    ),

    // Page 7: The Lifetime Impact Dashboard
    GoRoute(
      path: '/impact-stats',
      builder: (context, state) => const ImpactDashboardPage(),
    ),
  ],
);
*/




/*import 'package:go_router/go_router.dart';
import 'package:hervest_ai/bottom_navigation/bottom_navigation.dart';
import 'package:hervest_ai/bottom_navigation/inventory_page_four.dart';
import 'package:hervest_ai/bottom_navigation/inventory_page_three.dart';
import 'package:hervest_ai/bottom_navigation/inventory_page_two.dart';
import 'package:hervest_ai/bottom_navigation/inventory_screen.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/features/onboarding/onboarding_first_page.dart';
import 'package:hervest_ai/features/onboarding/onboarding_second_page.dart';
import 'package:hervest_ai/features/onboarding/onboarding_third_page.dart';
import 'package:hervest_ai/features/onboarding/splash_screen.dart';
import 'package:hervest_ai/pages/forgotpw_enter_email.dart';
import 'package:hervest_ai/pages/forgotpw_check_email.dart';
import 'package:hervest_ai/pages/forgotpw_otp.dart';
import 'package:hervest_ai/pages/landing_page.dart';
import 'package:hervest_ai/pages/reset_password.dart';
import 'package:hervest_ai/pages/signin_page.dart';
import 'package:hervest_ai/pages/signup_page.dart';


final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    
    // ... (Your onboarding routes remain unchanged)
    GoRoute(
      path: '/onboarding-1',
      builder: (context, state) => OnboardingFirstScreen(
        onNext: () => context.go('/onboarding-2'),
        onSkip: () async {
          await AppSessionStore.instance.setHasSeenOnboarding(true);
          final isLoggedIn = await AppSessionStore.instance.isLoggedIn();
          if (context.mounted) context.go(isLoggedIn ? '/dashboard' : '/landing');
        },
        onClose: () async {
          await AppSessionStore.instance.setHasSeenOnboarding(true);
          final isLoggedIn = await AppSessionStore.instance.isLoggedIn();
          if (context.mounted) context.go(isLoggedIn ? '/dashboard' : '/landing');
        },
      ),
    ),
    GoRoute(
      path: '/onboarding-2',
      builder: (context, state) => OnboardingSecondScreen(
        onNext: () => context.go('/onboarding-3'),
        onBack: () => context.go('/onboarding-1'),
        onClose: () async {
          await AppSessionStore.instance.setHasSeenOnboarding(true);
          final isLoggedIn = await AppSessionStore.instance.isLoggedIn();
          if (context.mounted) context.go(isLoggedIn ? '/dashboard' : '/landing');
        },
      ),
    ),
    GoRoute(
      path: '/onboarding-3',
      builder: (context, state) => OnboardingThirdScreen(
        onBack: () => context.go('/onboarding-2'),
        onFinish: () async {
          await AppSessionStore.instance.setHasSeenOnboarding(true);
          final isLoggedIn = await AppSessionStore.instance.isLoggedIn();
          if (context.mounted) context.go(isLoggedIn ? '/dashboard' : '/landing');
        },
        onClose: () async {
          await AppSessionStore.instance.setHasSeenOnboarding(true);
          final isLoggedIn = await AppSessionStore.instance.isLoggedIn();
          if (context.mounted) context.go(isLoggedIn ? '/dashboard' : '/landing');
        },
      ),
    ),

    // Auth Routes
    GoRoute(path: '/landing', builder: (context, state) => const LandingPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
    
    // Forgot Password Flow
    GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordEmailScreen()),
    GoRoute(
      path: '/forgot-password/check-email/:email',
      builder: (context, state) => CheckEmailScreen(email: Uri.decodeComponent(state.pathParameters['email'] ?? '')),
    ),
    GoRoute(
      path: '/forgot-password/enter-code/:email',
      builder: (context, state) => EnterCodeScreen(email: Uri.decodeComponent(state.pathParameters['email'] ?? '')),
    ),
    GoRoute(
      path: '/forgot-password/reset-password/:email',
      builder: (context, state) => ResetPasswordScreen(email: Uri.decodeComponent(state.pathParameters['email'] ?? '')),
    ),

    // Dashboard (Main Navigation)
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MainNavigationScreen(),
    ),

    // --- NEW INVENTORY FLOW ROUTES ---
    
    // Page 1: Main List (Accessible via Bottom Nav or via /inventory)
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const InventoryPageOne(),
    ),
    
    // Page 2: Manual Add Form
    GoRoute(
      path: '/inventory/add',
      builder: (context, state) => const InventoryPageTwo(),
    ),
    
    // Page 3: Review Table
    GoRoute(
      path: '/inventory/review',
      builder: (context, state) => const InventoryPageThree(),
    ),
    
    // Page 4: Success Summary
    GoRoute(
      path: '/inventory/success',
      builder: (context, state) => const InventoryPageFour(),
    ),
  ],
); */








