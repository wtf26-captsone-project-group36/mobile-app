import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';

// Models
import 'package:hervest_ai/models/inventory_model.dart';

// Onboarding and auth
import 'package:hervest_ai/features/onboarding/splash_screen.dart';
import 'package:hervest_ai/features/onboarding/onboarding_first_page.dart';
import 'package:hervest_ai/features/onboarding/onboarding_second_page.dart';
import 'package:hervest_ai/features/onboarding/onboarding_third_page.dart';
import 'package:hervest_ai/pages/landing_page.dart';
import 'package:hervest_ai/pages/signin_page.dart';
import 'package:hervest_ai/pages/signup_page.dart';
import 'package:hervest_ai/pages/forgotpw_enter_email.dart';
import 'package:hervest_ai/pages/forgotpw_check_email.dart';
import 'package:hervest_ai/pages/forgotpw_otp.dart';
import 'package:hervest_ai/pages/reset_password.dart';
import 'package:hervest_ai/pages/facebook_auth_mock_page.dart';
import 'package:hervest_ai/pages/whatsapp_auth_mock_page.dart';
import 'package:hervest_ai/pages/account_settings_page.dart';

// Shell + tab roots
import 'package:hervest_ai/bottom_navigation/bottom_navigation.dart';
import 'package:hervest_ai/pages/dashboard_page.dart';
import 'package:hervest_ai/bottom_navigation/inventory_screen.dart';
import 'package:hervest_ai/bottom_navigation/cashflow_screen.dart';
import 'package:hervest_ai/bottom_navigation/suggestions_screen.dart';
import 'package:hervest_ai/bottom_navigation/profile_screen.dart';

// Inventory flow
import 'package:hervest_ai/bottom_navigation/inventory_page_two.dart';
import 'package:hervest_ai/bottom_navigation/inventory_page_three.dart';
import 'package:hervest_ai/bottom_navigation/inventory_page_four.dart';

// Suggestions and impact
import 'package:hervest_ai/bottom_navigation/suggestions_logistics_page.dart';
import 'package:hervest_ai/bottom_navigation/sugg_impact_dashboard_page.dart';
import 'package:hervest_ai/bottom_navigation/rescue_pledges_history_page.dart';

// Cashflow flow
import 'package:hervest_ai/bottom_navigation/cashflow_addexpense_page.dart';
import 'package:hervest_ai/bottom_navigation/cashflow_addincome_page.dart';
import 'package:hervest_ai/bottom_navigation/cashflow_transactionhistory_page.dart';

// Search overlay
import 'package:hervest_ai/bottom_navigation/search/global_search_overlay.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>();
final _shellNavigatorInventoryKey = GlobalKey<NavigatorState>();
final _shellNavigatorCashflowKey = GlobalKey<NavigatorState>();
final _shellNavigatorSuggestionsKey = GlobalKey<NavigatorState>();
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Initial entry
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding-1',
      builder: (context, state) => OnboardingFirstScreen(
        onNext: () => context.go('/onboarding-2'),
        onSkip: () async {
          await AppSessionStore.instance.setHasSeenOnboarding(true);
          final isLoggedIn = await AppSessionStore.instance.isLoggedIn();
          if (context.mounted) {
            context.go(isLoggedIn ? '/dashboard' : '/landing');
          }
        },
        onClose: () async {
          await AppSessionStore.instance.setHasSeenOnboarding(true);
          final isLoggedIn = await AppSessionStore.instance.isLoggedIn();
          if (context.mounted) {
            context.go(isLoggedIn ? '/dashboard' : '/landing');
          }
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
          if (context.mounted) {
            context.go(isLoggedIn ? '/dashboard' : '/landing');
          }
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
          if (context.mounted) {
            context.go(isLoggedIn ? '/dashboard' : '/landing');
          }
        },
        onClose: () async {
          await AppSessionStore.instance.setHasSeenOnboarding(true);
          final isLoggedIn = await AppSessionStore.instance.isLoggedIn();
          if (context.mounted) {
            context.go(isLoggedIn ? '/dashboard' : '/landing');
          }
        },
      ),
    ),
    GoRoute(path: '/landing', builder: (context, state) => const LandingPage()),
    GoRoute(
      path: '/auth/whatsapp-mock',
      builder: (context, state) => const WhatsAppAuthMockPage(),
    ),
    GoRoute(
      path: '/auth/facebook-mock',
      builder: (context, state) => const FacebookAuthMockPage(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
    GoRoute(
      path: '/account-settings',
      builder: (context, state) => const AccountSettingsPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordEmailScreen(),
    ),
    GoRoute(
      path: '/forgot-password/check-email/:email',
      builder: (context, state) => CheckEmailScreen(
        email: Uri.decodeComponent(state.pathParameters['email']!),
      ),
    ),
    GoRoute(
      path: '/forgot-password/enter-code/:email',
      builder: (context, state) => EnterCodeScreen(
        email: Uri.decodeComponent(state.pathParameters['email']!),
      ),
    ),
    GoRoute(
      path: '/forgot-password/reset-password/:email',
      builder: (context, state) => ResetPasswordScreen(
        email: Uri.decodeComponent(state.pathParameters['email']!),
      ),
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          const MaterialPage(fullscreenDialog: true, child: GlobalSearchPage()),
    ),

    // Main app shell (bottom nav)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainNavigationScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHomeKey,
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorInventoryKey,
          routes: [
            GoRoute(
              path: '/inventory',
              builder: (context, state) => const InventoryPageOne(),
              routes: [
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const InventoryPageTwo(),
                ),
                GoRoute(
                  path: 'review',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const InventoryPageThree(),
                ),
                GoRoute(
                  path: 'success',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const InventoryPageFour(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorCashflowKey,
          routes: [
            GoRoute(
              path: '/cashflow',
              builder: (context, state) => const CashflowScreen(),
              routes: [
                GoRoute(
                  path: 'add-expense',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const AddExpensePage(),
                ),
                GoRoute(
                  path: 'add-income',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const AddIncomePage(),
                ),
                GoRoute(
                  path: 'transactions',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const TransactionHistoryPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorSuggestionsKey,
          routes: [
            GoRoute(
              path: '/suggestions',
              builder: (context, state) => const SuggestionsScreen(),
              routes: [
                GoRoute(
                  path: 'pledges',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const RescuePledgesHistoryPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorProfileKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),

    // Suggestions and impact details
    GoRoute(
      path: '/suggestion-logistics',
      parentNavigatorKey: _rootNavigatorKey,
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
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ImpactDashboardPage(),
    ),
  ],
);
