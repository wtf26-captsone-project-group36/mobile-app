import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/provider/inventory_provider.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
import 'package:hervest_ai/provider/rescue_provider.dart';
import 'package:hervest_ai/models/inventory_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedTab = 0;

  final Color primaryGreen = const Color(0xFF006B4D);
  final Color backgroundCream = const Color(0xFFFDFBF7);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 600;

    // We wrap the body in a Consumer2 to react to data changes from both providers
    return Consumer2<InventoryProvider, AppStateController>(
      builder: (context, invProvider, appState, child) {
        return Scaffold(
          backgroundColor: backgroundCream,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  collapsedHeight: 80,
                  pinned: true,
                  backgroundColor: backgroundCream,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildProfileRow(appState.userName),
                          const SizedBox(height: 20),
                          _buildSearchTrigger(context),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTabSwitcher(),
                      const SizedBox(height: 24),
                      selectedTab == 0
                          ? _buildOverviewGrid(isWideScreen, invProvider, appState)
                          : _buildRecentActivity(invProvider, appState),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ================= DYNAMIC UI COMPONENTS =================

  Widget _buildProfileRow(String name) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Responsive logo size
    final logoWidth = isMobile ? 45.0 : 55.0;
    final logoHeight = isMobile ? 35.0 : 42.0;
    final nameFontSize = isMobile ? 20.0 : 26.0;
    final welcomeFontSize = isMobile ? 12.0 : 14.0;
    final spacing = isMobile ? 12.0 : 16.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo and Text Section (Side by Side)
        Flexible(
          child: Row(
            children: [
              // HerVest AI Logo
              Container(
                width: logoWidth,
                height: logoHeight,
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      'assets/hervbypd.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image,
                          color: Colors.white,
                          size: isMobile ? 16 : 20,
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacing),
              // Welcome Text
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Welcome back,",
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.5),
                        fontSize: welcomeFontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 4 : 6),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: nameFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: spacing),
        // Avatar Section
        _buildAvatar(name),
      ],
    );
  }

  Widget _buildAvatar(String name) {
    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: primaryGreen.withValues(alpha: 0.2), width: 2),
        ),
        child: CircleAvatar(
          radius: 26,
          backgroundColor: primaryGreen,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "U",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewGrid(
    bool isWide,
    InventoryProvider inv,
    AppStateController appState,
  ) {
    final netBalance = (appState.cashflowReport['net_balance'] as num?)?.toDouble();
    final prediction = appState.latestPredictions['cashflow_prediction'];
    final riskLevel = prediction is Map<String, dynamic>
        ? (prediction['risk_level'] ?? '').toString().trim()
        : '';
    final cashflowValue = netBalance == null
        ? "NGN ${(inv.totalLedgerValue / 1000).toStringAsFixed(0)}k"
        : "NGN ${_formatCompactNgn(netBalance)}";
    final alertsCount = appState.criticalAlerts > 0
        ? appState.criticalAlerts
        : inv.criticalCount;

    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 4 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            // Real data pulled from InventoryProvider
            _statCard(
              "Inventory",
              "${inv.items.length} Items",
              Icons.inventory_2_outlined,
              Colors.blue,
              '/inventory',
            ),
            _statCard(
              "Cashflow",
              riskLevel.isEmpty ? cashflowValue : "$cashflowValue • $riskLevel",
              Icons.account_balance_wallet_outlined,
              Colors.orange,
              '/cashflow',
            ),
            _statCard(
              "AI Alerts",
              "$alertsCount Critical",
              Icons.auto_awesome_outlined,
              Colors.red,
              '/suggestions',
            ),
            _statCard(
              "Impact",
              "50 Points",
              Icons.volunteer_activism_outlined,
              Colors.teal,
              '/impact-stats',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRescueAssistantEntry(),
      ],
    );
  }

  String _formatCompactNgn(double value) {
    final abs = value.abs();
    if (abs >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildRescueAssistantEntry() {
    return GestureDetector(
      onTap: () {
        context.read<RescueProvider>().requestAssistantOpen();
        context.go('/suggestions');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryGreen.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.smart_toy_outlined, color: primaryGreen),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Rescue Assistant: Ask what to rescue today',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Chip(
              label: const Text('Open'),
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(color: primaryGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(InventoryProvider inv, AppStateController appState) {
    if (appState.alerts.isNotEmpty || appState.activities.isNotEmpty) {
      final tiles = <Widget>[];
      for (final alert in appState.alerts.take(5)) {
        final id = (alert['id'] ?? '').toString();
        final title = (alert['alert_type'] ?? 'Alert').toString();
        final message = (alert['message'] ?? '').toString();
        final isRead = alert['is_read'] == true;

        tiles.add(
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: isRead
                  ? Colors.blue.withValues(alpha: 0.12)
                  : Colors.red.withValues(alpha: 0.12),
              child: Icon(
                isRead ? Icons.notifications_none : Icons.priority_high,
                size: 18,
                color: isRead ? Colors.blue : Colors.red,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(message),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (id.isEmpty) return;
                if (value == 'read') {
                  await appState.markAlertRead(id);
                } else if (value == 'resolve') {
                  await appState.resolveAlert(id);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'read', child: Text('Mark as Read')),
                PopupMenuItem(value: 'resolve', child: Text('Resolve Alert')),
              ],
            ),
          ),
        );
      }

      for (final activity in appState.activities.take(5)) {
        final action = (activity['action'] ?? 'Activity').toString();
        final entity = (activity['entity_type'] ?? '').toString();
        final createdAt = (activity['created_at'] ?? '').toString();
        final created = DateTime.tryParse(createdAt);

        tiles.add(
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.12),
              child: const Icon(Icons.history, size: 18, color: Colors.orange),
            ),
            title: Text(
              action,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              created == null
                  ? entity
                  : '$entity • ${created.toLocal().toString().split('.').first}',
            ),
          ),
        );
      }

      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: tiles,
      );
    }

    // Only show items that are warning or expired
    final items = inv.items
        .where((i) => i.status != ItemStatus.normal)
        .toList();

    if (items.isEmpty) {
      return const Center(
        child: Text(
          "No recent critical activity",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: item.status == ItemStatus.expired
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            child: Icon(
              Icons.history,
              size: 18,
              color: item.status == ItemStatus.expired
                  ? Colors.red
                  : Colors.orange,
            ),
          ),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(item.errorMessage ?? "Action required soon"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/inventory'),
        );
      },
    );
  }

  Widget _buildSearchTrigger(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/search'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.grey, size: 22),
            SizedBox(width: 12),
            Text(
              "Search for items or transactions...",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [_tabItem("Overview", 0), _tabItem("Recent Activity", 1)],
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    bool isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primaryGreen : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String route,
  ) {
    return _StatCard(
      title: title,
      value: value,
      icon: icon,
      color: color,
      onTap: () => context.push(route),
    );
  }
}

class _StatCard extends StatefulWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _isHovered || _isPressed;
    final Color borderColor = active
        ? widget.color.withValues(alpha: 0.55)
        : widget.color.withValues(alpha: 0.18);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapCancel: () => setState(() => _isPressed = false),
        onTapUp: (_) => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          transform: active
              ? (Matrix4.identity()..translate(0.0, -4.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: active ? 0.12 : 0.06),
                blurRadius: active ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: active ? 0.18 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    widget.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
