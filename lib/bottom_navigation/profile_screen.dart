import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
import 'package:hervest_ai/provider/profile_controller.dart';
import 'package:hervest_ai/widgets/app_input_styles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  final Color primaryGreen = const Color(0xFF006B4D);
  final Color backgroundCream = const Color(0xFFFDFBF7);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final profile = context.read<ProfileController>();
      profile.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateController>(context);
    final profile = Provider.of<ProfileController>(context);

    return Scaffold(
      backgroundColor: widget.backgroundCream,
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
            onPressed: () => _showEditProfileSheet(context, profile, state),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            _buildAvatarHeader(profile),
            const SizedBox(height: 32),
            _buildProfileDetails(profile),
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

  Widget _buildAvatarHeader(ProfileController profile) {
    final String displayName = profile.fullName.isNotEmpty
        ? profile.fullName
        : (profile.email.isNotEmpty ? profile.email : '');
    final String roleText = profile.role.isNotEmpty ? profile.role : '';
    final File? avatarFile = profile.avatarFile;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: widget.primaryGreen.withOpacity(0.15),
              backgroundImage: avatarFile != null ? FileImage(avatarFile) : null,
              child: avatarFile == null
                  ? Text(
                      _initialsFrom(displayName),
                      style: TextStyle(
                        color: widget.primaryGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _pickAvatar(profile),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.camera_alt, color: widget.primaryGreen, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (displayName.isNotEmpty)
          Text(
            displayName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          )
        else
          const Text(
            "Complete your profile",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        if (roleText.isNotEmpty)
          Text(roleText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        if (displayName.isEmpty || roleText.isEmpty)
          TextButton(
            onPressed: () => _showEditProfileSheet(
              context,
              profile,
              context.read<AppStateController>(),
            ),
            child: Text(
              "Add details",
              style: TextStyle(color: widget.primaryGreen, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileDetails(ProfileController profile) {
    final rows = <Widget>[];
    void addRow(IconData icon, String label, String value) {
      if (value.isEmpty) return;
      rows.add(_infoRow(icon, label, value));
    }

    addRow(Icons.email_outlined, "Email", profile.email);
    addRow(Icons.phone_outlined, "Phone", profile.phone);
    addRow(Icons.business_outlined, "Business", profile.businessName);
    addRow(Icons.storefront_outlined, "Business Type", profile.businessType);
    addRow(Icons.badge_outlined, "Role", profile.role);
    addRow(Icons.location_on_outlined, "Location", profile.location);

    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: const Text(
          "No profile details yet. Tap the settings icon to add your details.",
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildNotificationSection(AppStateController state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Notification Settings",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "Manage your alert preferences",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 20),
        _toggleCard(
          "Expiry Alerts",
          "Get notified when items are near expiry",
          state.expiryAlertsEnabled,
          (val) => state.toggleExpiryAlerts(val),
          Icons.warning_amber_rounded,
          Colors.orange,
        ),
        _toggleCard(
          "Cashflow Updates",
          "Daily summaries and AI predictions",
          state.cashflowUpdatesEnabled,
          (val) => state.toggleCashflowUpdates(val),
          Icons.trending_up_rounded,
          Colors.blue,
        ),
        _toggleCard(
          "Low Stock Warnings",
          "Alert when inventory is running low",
          state.lowStockEnabled,
          (val) => state.toggleLowStock(val),
          Icons.shopping_cart_outlined,
          Colors.red,
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: widget.primaryGreen, size: 22),
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

  Widget _toggleCard(
    String title,
    String sub,
    bool val,
    Function(bool) onToggle,
    IconData icon,
    Color color,
  ) {
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Switch.adaptive(value: val, activeColor: widget.primaryGreen, onChanged: onToggle),
        ],
      ),
    );
  }

  Future<void> _pickAvatar(ProfileController profile) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image == null) return;
    await profile.updateAvatarPath(image.path);
  }

  void _showEditProfileSheet(
    BuildContext context,
    ProfileController profile,
    AppStateController appState,
  ) {
    final nameController = TextEditingController(text: profile.fullName);
    final emailController = TextEditingController(text: profile.email);
    final phoneController = TextEditingController(text: profile.phone);
    final businessController = TextEditingController(text: profile.businessName);
    final locationController = TextEditingController(text: profile.location);
    String role = profile.role;
    String businessType = profile.businessType;

    const roles = ['Owner', 'Manager', 'Staff', 'Admin'];
    const businessTypes = [
      'Restaurant',
      'Store Owner',
      'Food Vendor',
      'Farmer/Agricultural Business',
      'Bakery',
      'Catering Service',
      'Cafe/Bistro',
      'Cafeteria',
      'Buka',
      'Mini-Mart',
      'Kiosk',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Edit Profile",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: AppInputStyles.decoration(labelText: "Full Name"),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: AppInputStyles.decoration(labelText: "Email"),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: AppInputStyles.decoration(labelText: "Phone"),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: businessController,
                  decoration: AppInputStyles.decoration(labelText: "Business Name"),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: businessType.isEmpty ? null : businessType,
                  decoration: AppInputStyles.decoration(labelText: "Business Type"),
                  items: businessTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (val) => setSheetState(() => businessType = val ?? ''),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: role.isEmpty ? null : role,
                  decoration: AppInputStyles.decoration(labelText: "Role"),
                  items: roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) => setSheetState(() => role = val ?? ''),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: locationController,
                  decoration: AppInputStyles.decoration(labelText: "Location"),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await profile.updateProfile(
                        fullName: nameController.text.trim(),
                        email: emailController.text.trim(),
                        phone: phoneController.text.trim(),
                        businessName: businessController.text.trim(),
                        role: role.trim(),
                        businessType: businessType.trim(),
                        location: locationController.text.trim(),
                      );
                      if (nameController.text.trim().isNotEmpty) {
                        appState.setUserName(nameController.text.trim());
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton.icon(
      onPressed: () => _confirmLogout(context),
      icon: const Icon(Icons.logout, color: Colors.redAccent),
      label: const Text(
        "Log Out",
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _initialsFrom(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return "?";
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].isNotEmpty ? parts[0][0] : '') +
        (parts[1].isNotEmpty ? parts[1][0] : '');
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log out?"),
        content: const Text("You can log back in anytime."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    await AppSessionStore.instance.setLoggedIn(false);
    await AppSessionStore.instance.setGuestMode(false);
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.go('/landing');
    }
  }
}
