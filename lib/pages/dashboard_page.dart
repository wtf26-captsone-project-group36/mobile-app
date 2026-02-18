import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
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
