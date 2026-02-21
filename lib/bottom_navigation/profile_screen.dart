import 'package:flutter/material.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
import 'package:provider/provider.dart';
import 'package:hervest_ai/widgets/app_input_styles.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  final Color primaryGreen = const Color(0xFF006B4D);
  final Color backgroundCream = const Color(0xFFFDFBF7);

  @override
  Widget build(BuildContext context) {
    // Listen to the AppStateController for toggle values
    final state = Provider.of<AppStateController>(context);

    return Scaffold(
      backgroundColor: backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () => _showEditProfileSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            _buildAvatarHeader(),
            const SizedBox(height: 32),
            _buildProfileDetails(),
            const SizedBox(height: 40),
            _buildNotificationSection(state),
            const SizedBox(height: 40),
            _buildLogoutButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: primaryGreen,
              child: const Text("AA", 
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.camera_alt, color: primaryGreen, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text("Abah Adam", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const Text("Business Owner", style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildProfileDetails() {
    return Column(
      children: [
        _infoRow(Icons.email_outlined, "Email", "Abahadam@gmail.com"),
        _infoRow(Icons.phone_outlined, "Phone", "+234700000000"),
        _infoRow(Icons.business_outlined, "Business", "Abah's Restaurant"),
        _infoRow(Icons.location_on_outlined, "Location", "Lagos, Nigeria"),
      ],
    );
  }

  Widget _buildNotificationSection(AppStateController state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Notification Settings", 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Manage your alert preferences", 
          style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 20),
        _toggleCard(
          "Expiry Alerts", "Get notified when items are near expiry", 
          state.expiryAlertsEnabled, (val) => state.toggleExpiryAlerts(val), 
          Icons.warning_amber_rounded, Colors.orange
        ),
        _toggleCard(
          "Cashflow Updates", "Daily summaries and AI predictions", 
          state.cashflowUpdatesEnabled, (val) => state.toggleCashflowUpdates(val), 
          Icons.trending_up_rounded, Colors.blue
        ),
        _toggleCard(
          "Low Stock Warnings", "Alert when inventory is running low", 
          state.lowStockEnabled, (val) => state.toggleLowStock(val), 
          Icons.shopping_cart_outlined, Colors.red
        ),
      ],
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleCard(String title, String sub, bool val, Function(bool) onToggle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ),
          Switch.adaptive(value: val, activeColor: primaryGreen, onChanged: onToggle),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Edit Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              decoration: AppInputStyles.decoration(labelText: "Full Name"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, minimumSize: const Size(double.infinity, 50)),
              onPressed: () => Navigator.pop(context),
              child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.logout, color: Colors.redAccent),
      label: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
    );
  }
}
