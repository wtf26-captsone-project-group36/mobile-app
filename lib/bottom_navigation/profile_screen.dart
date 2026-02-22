import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hervest_ai/core/storage/app_session_store.dart';
import 'package:hervest_ai/core/utils/user_name_utils.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileController>().load();
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
            onPressed: () => context.push('/account-settings'),
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
            _buildProfileDetails(profile, state),
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
    final Uint8List? avatarBytes = profile.avatarBytes;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: widget.primaryGreen.withValues(alpha: 0.15),
              backgroundImage: avatarBytes != null ? MemoryImage(avatarBytes) : null,
              child: avatarBytes == null
                  ? Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.primaryGreen.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: widget.primaryGreen,
                        size: 48,
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
                onTap: () => _showAvatarOptions(profile),
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
          Text(
            'Use the edit icons below to complete your details.',
            style: TextStyle(
              color: widget.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildProfileDetails(ProfileController profile, AppStateController appState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _editableRow(
            icon: Icons.person_outline,
            label: "Full Name",
            value: profile.fullName,
            onEdit: () => _editTextField(
              title: 'Edit Full Name',
              initialValue: profile.fullName,
              label: 'Full Name',
              onSave: (value) => _saveProfilePatch(
                profile,
                appState,
                fullName: value,
              ),
            ),
          ),
          _editableRow(
            icon: Icons.email_outlined,
            label: "Email",
            value: profile.email,
            onEdit: () => _editTextField(
              title: 'Edit Email',
              initialValue: profile.email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              onSave: (value) => _saveProfilePatch(
                profile,
                appState,
                email: value,
              ),
            ),
          ),
          _editableRow(
            icon: Icons.phone_outlined,
            label: "Phone",
            value: profile.phone,
            onEdit: () => _editTextField(
              title: 'Edit Phone',
              initialValue: profile.phone,
              label: 'Phone',
              keyboardType: TextInputType.phone,
              onSave: (value) => _saveProfilePatch(
                profile,
                appState,
                phone: value,
              ),
            ),
          ),
          _editableRow(
            icon: Icons.business_outlined,
            label: "Business",
            value: profile.businessName,
            onEdit: () => _editTextField(
              title: 'Edit Business Name',
              initialValue: profile.businessName,
              label: 'Business Name',
              onSave: (value) => _saveProfilePatch(
                profile,
                appState,
                businessName: value,
              ),
            ),
          ),
          _editableRow(
            icon: Icons.storefront_outlined,
            label: "Business Type",
            value: profile.businessType,
            onEdit: () => _editSelectionField(
              title: 'Select Business Type',
              current: profile.businessType,
              options: const [
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
              ],
              onSave: (value) => _saveProfilePatch(
                profile,
                appState,
                businessType: value,
              ),
            ),
          ),
          _editableRow(
            icon: Icons.badge_outlined,
            label: "Role",
            value: profile.role,
            onEdit: () => _editSelectionField(
              title: 'Select Role',
              current: profile.role,
              options: const ['Owner', 'Manager', 'Staff', 'Admin'],
              onSave: (value) => _saveProfilePatch(
                profile,
                appState,
                role: value,
              ),
            ),
          ),
          _editableRow(
            icon: Icons.location_on_outlined,
            label: "Location",
            value: profile.location,
            onEdit: () => _editTextField(
              title: 'Edit Location',
              initialValue: profile.location,
              label: 'Location',
              onSave: (value) => _saveProfilePatch(
                profile,
                appState,
                location: value,
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _editableRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    final bool hasValue = value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: widget.primaryGreen, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  hasValue ? value : 'Not set',
                  style: TextStyle(
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 15,
                    color: hasValue ? Colors.black87 : Colors.black45,
                    fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit $label',
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, color: widget.primaryGreen, size: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfilePatch(
    ProfileController profile,
    AppStateController appState, {
    String? fullName,
    String? email,
    String? phone,
    String? businessName,
    String? role,
    String? businessType,
    String? location,
  }) async {
    final nextFullName = fullName ?? profile.fullName;
    final nextEmail = email ?? profile.email;

    await profile.updateProfile(
      fullName: nextFullName,
      email: nextEmail,
      phone: phone ?? profile.phone,
      businessName: businessName ?? profile.businessName,
      role: role ?? profile.role,
      businessType: businessType ?? profile.businessType,
      location: location ?? profile.location,
    );

    if (nextFullName.trim().isNotEmpty) {
      appState.setUserName(nextFullName.trim());
    } else if (nextEmail.trim().isNotEmpty) {
      appState.setUserName(displayNameFromEmail(nextEmail.trim()));
    }
  }

  Future<void> _editTextField({
    required String title,
    required String initialValue,
    required String label,
    required Future<void> Function(String value) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: keyboardType,
            decoration: AppInputStyles.decoration(labelText: label),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await onSave(controller.text.trim());
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editSelectionField({
    required String title,
    required String current,
    required List<String> options,
    required Future<void> Function(String value) onSave,
  }) async {
    String selected = current;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: DropdownButtonFormField<String>(
            initialValue: selected.isEmpty ? null : selected,
            decoration: AppInputStyles.decoration(labelText: title),
            items: options
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setDialogState(() => selected = value ?? ''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selected.trim().isEmpty
                  ? null
                  : () async {
                      await onSave(selected.trim());
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                    },
              child: const Text('Save'),
            ),
          ],
        ),
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
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
          Switch.adaptive(
            value: val,
            activeThumbColor: widget.primaryGreen,
            activeTrackColor: widget.primaryGreen.withValues(alpha: 0.4),
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar(ProfileController profile, ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      await profile.updateAvatarBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update photo: $e')),
      );
    }
  }

  Future<void> _showAvatarOptions(ProfileController profile) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _pickAvatar(profile, ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a photo'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _pickAvatar(profile, ImageSource.camera);
                  },
                ),
              if (profile.avatarBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remove photo'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await profile.clearAvatar();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile photo removed')),
                    );
                  },
                ),
            ],
          ),
        );
      },
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
