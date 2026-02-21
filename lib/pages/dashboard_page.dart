import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/provider/inventory_provider.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
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

    // We wrap the body in a Consumer to react to data changes
    return Consumer2<InventoryProvider, AppStateController>(
      builder: (context, invProvider, appState, child) {
        return Scaffold(
          backgroundColor: backgroundCream,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
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
                          ? _buildOverviewGrid(isWideScreen, invProvider)
                          : _buildRecentActivity(invProvider),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back,",
                style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14)),
            Text(name,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ],
        ),
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
          border: Border.all(color: primaryGreen.withOpacity(0.2), width: 2),
        ),
        child: CircleAvatar(
          radius: 26,
          backgroundColor: primaryGreen,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "U",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewGrid(bool isWide, InventoryProvider inv) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWide ? 4 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        // Real data pulled from InventoryProvider
        _statCard("Inventory", "${inv.items.length} Items", Icons.inventory_2_outlined, Colors.blue, '/inventory'),
        _statCard("Cashflow", "₦${(inv.totalLedgerValue / 1000).toStringAsFixed(0)}k", Icons.account_balance_wallet_outlined, Colors.orange, '/cashflow'),
        _statCard("AI Alerts", "${inv.criticalCount} Critical", Icons.auto_awesome_outlined, Colors.red, '/suggestions'),
        _statCard("Impact", "50 Points", Icons.volunteer_activism_outlined, Colors.teal, '/impact-stats'),
      ],
    );
  }

  Widget _buildRecentActivity(InventoryProvider inv) {
    // Only show items that are warning or expired
    final items = inv.items.where((i) => i.status != ItemStatus.normal).toList();

    if (items.isEmpty) {
      return const Center(child: Text("No recent critical activity", style: TextStyle(color: Colors.grey)));
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
            backgroundColor: item.status == ItemStatus.expired ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            child: Icon(Icons.history, size: 18, color: item.status == ItemStatus.expired ? Colors.red : Colors.orange),
          ),
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(item.errorMessage ?? "Action required soon"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/inventory'),
        );
      },
    );
  }

  // ... (Keep existing _buildSearchTrigger, _buildTabSwitcher, _tabItem, and _statCard)
  
  Widget _buildSearchTrigger(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/search'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.grey, size: 22),
            SizedBox(width: 12),
            const Text(
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
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tabItem("Overview", 0),
          _tabItem("Recent Activity", 1),
        ],
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

  Widget _statCard(String title, String value, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.02)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            )
          ],
        ),
      ),
    );
  }
}











/* MAIN import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedTab = 0;
  final String userName = "Anna"; 

  final Color primaryGreen = const Color(0xFF006B4D);
  final Color backgroundCream = const Color(0xFFFDFBF7);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: backgroundCream,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Using SliverAppBar to house the Header + Master Search
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
                      _buildProfileRow(),
                      const SizedBox(height: 20),
                      _buildSearchTrigger(context), // Integrated Search Button
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
                      ? _buildOverviewGrid(isWideScreen)
                      : _buildRecentActivity(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back,",
                style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14)),
            Text(userName,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ],
        ),
        _buildAvatar(),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryGreen.withOpacity(0.2), width: 2),
      ),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: primaryGreen,
        child: Text(
          userName[0].toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
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
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
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

  // ... (Keep your existing _buildTabSwitcher, _tabItem, _buildOverviewGrid, _statCard, and _buildRecentActivity as they are)
  
  Widget _buildTabSwitcher() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tabItem("Overview", 0),
          _tabItem("Recent Activity", 1),
        ],
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

  Widget _buildOverviewGrid(bool isWide) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWide ? 4 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _statCard("Inventory", "8 Items", Icons.inventory_2_outlined, Colors.blue, '/inventory'),
        _statCard("Cashflow", "₦250k", Icons.account_balance_wallet_outlined, Colors.orange, '/cashflow'),
        _statCard("AI Alerts", "3 Critical", Icons.auto_awesome_outlined, Colors.red, '/suggestions'),
        _statCard("Impact", "50 Points", Icons.volunteer_activism_outlined, Colors.teal, '/impact-stats'),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.02)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(child: Icon(Icons.history, size: 18)),
        title: const Text("Stock Expiring Soon", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Golden Penny Beans (7 days left)"),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

*/



/*import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedTab = 0;
  final String userName = "Anna"; // Dynamic name integration

  // Premium Brand Palette
  final Color primaryGreen = const Color(0xFF006B4D);
  final Color backgroundCream = const Color(0xFFFDFBF7);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: backgroundCream,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSearchTrigger(context),
                  const SizedBox(height: 24),
                  _buildTabSwitcher(),
                  const SizedBox(height: 24),
                  selectedTab == 0
                      ? _buildOverviewGrid(isWideScreen)
                      : _buildRecentActivity(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= APP BAR & AVATAR =================
  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14),
                ),
                Text(
                  userName,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            _buildAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryGreen.withOpacity(0.2), width: 2),
      ),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: primaryGreen,
        child: Text(
          userName[0].toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    );
  }

  /// ================= MASTER SEARCH TRIGGER =================
  Widget _buildSearchTrigger(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/search'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.grey, size: 22),
            SizedBox(width: 12),
            Text(
              "Search inventory or cashflow...",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= TAB SYSTEM =================
  Widget _buildTabSwitcher() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tabItem("Overview", 0),
          _tabItem("Recent Activity", 1),
        ],
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
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
                : [],
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

  /// ================= GRID & CARDS =================
  Widget _buildOverviewGrid(bool isWide) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWide ? 4 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _statCard("Inventory", "8 Items", Icons.inventory_2_outlined, Colors.blue, '/inventory'),
        _statCard("Cashflow", "₦250k", Icons.account_balance_wallet_outlined, Colors.orange, '/cashflow'),
        _statCard("AI Alerts", "3 Critical", Icons.auto_awesome_outlined, Colors.red, '/suggestions'),
        _statCard("Impact", "50 Points", Icons.volunteer_activism_outlined, Colors.teal, '/impact-stats'),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.02)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(child: Icon(Icons.history, size: 18)),
        title: const Text("Stock Expiring Soon", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Golden Penny Beans (7 days left)"),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}*/

/*class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedTab = 0; // 0 = Overview, 1 = Recent Activity

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4), // soft mint green
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabSwitcher(),
            const SizedBox(height: 12),
            Expanded(
              child: selectedTab == 0
                  ? _buildOverviewGrid()
                  : _buildRecentActivity(),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= HEADER =================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "HerVest AI",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Smart Food Management",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Full dashboard access",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// ================= TAB SWITCHER =================
  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _tabButton("Overview", 0),
          const SizedBox(width: 10),
          _tabButton("Recent Activity", 1),
        ],
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade600 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                )
            ],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= OVERVIEW GRID =================
  Widget _buildOverviewGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: 4,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _inventoryCard();
              case 1:
                return _cashflowCard();
              case 2:
                return _alertsCard();
              default:
                return _marketplaceCard();
            }
          },
        );
      },
    );
  }

  /// ================= RECENT ACTIVITY =================
  Widget _buildRecentActivity() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ListTile(
          leading: Icon(Icons.warning, color: Colors.red),
          title: Text("2 Critical Alerts triggered"),
          subtitle: Text("Expired inventory detected"),
        ),
        ListTile(
          leading: Icon(Icons.shopping_cart, color: Colors.green),
          title: Text("New surplus item listed"),
          subtitle: Text("Tomatoes (20kg) added to marketplace"),
        ),
        ListTile(
          leading: Icon(Icons.attach_money, color: Colors.blue),
          title: Text("₦35,000 inflow recorded"),
          subtitle: Text("Marketplace sale completed"),
        ),
      ],
    );
  }

  /// ================= DASHBOARD CARDS =================
  Widget _inventoryCard() {
    return LiftOffCard(
      borderColor: Colors.green,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Inventory",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Spacer(),
          Text("8",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text("Total items in stock"),
        ],
      ),
    );
  }

  Widget _cashflowCard() {
    return LiftOffCard(
      borderColor: Colors.orange,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Cashflow",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Spacer(),
          Text("Balance: ₦192,000",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _alertsCard() {
    return LiftOffCard(
      borderColor: Colors.red,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("AI Risk Alerts",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Spacer(),
          Text("2 Critical | 1 High"),
        ],
      ),
    );
  }

  Widget _marketplaceCard() {
    return LiftOffCard(
      borderColor: Colors.green,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Surplus",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Spacer(),
          Text("5 Items Available"),
        ],
      ),
    );
  }
}

/// ================= LIFT-OFF CARD =================
class LiftOffCard extends StatefulWidget {
  final Widget child;
  final Color borderColor;

  const LiftOffCard({
    super.key,
    required this.child,
    required this.borderColor,
  });

  @override
  State<LiftOffCard> createState() => _LiftOffCardState();
}

class _LiftOffCardState extends State<LiftOffCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isHovered = true),
        onTapUp: (_) => setState(() => isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: isHovered
              ? (Matrix4.identity()..translateByDouble(0.0, -6.0, 0.0, 1.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isHovered ? 0.2 : 0.08,
                ),
                blurRadius: isHovered ? 20 : 10,
                offset: const Offset(0, 8),
              )
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: widget.child,
        ),
      ),
    );
  }
}
*/