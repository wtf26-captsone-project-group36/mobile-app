import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  static const Color kPrimaryGreen = Color(0xFF006B4D);
  static const Color kBackgroundCream = Color(0xFFFDFBF7);

  static const String _currencyKey = 'settings_currency';
  static const String _timezoneKey = 'settings_timezone';
  static const String _languageKey = 'settings_language';
  static const String _summaryDayKey = 'settings_summary_day';
  static const String _summaryHourKey = 'settings_summary_hour';
  static const String _pushAlertsKey = 'settings_push_alerts';
  static const String _emailAlertsKey = 'settings_email_alerts';
  static const String _whatsappAlertsKey = 'settings_whatsapp_alerts';
  static const String _twoFaKey = 'settings_two_fa';
  static const String _analyticsConsentKey = 'settings_analytics_consent';

  final List<String> _currencies = ['NGN', 'USD', 'EUR', 'GBP'];
  final List<String> _timezones = [
    'Africa/Lagos',
    'UTC',
    'America/New_York',
    'Europe/London',
  ];
  final List<String> _languages = ['English', 'French', 'Spanish'];
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String _currency = 'NGN';
  String _timezone = 'Africa/Lagos';
  String _language = 'English';
  String _summaryDay = 'Monday';
  int _summaryHour = 8;
  bool _pushAlerts = true;
  bool _emailAlerts = true;
  bool _whatsappAlerts = false;
  bool _twoFactor = false;
  bool _analyticsConsent = true;
  bool _isLoaded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currency = prefs.getString(_currencyKey) ?? _currency;
      _timezone = prefs.getString(_timezoneKey) ?? _timezone;
      _language = prefs.getString(_languageKey) ?? _language;
      _summaryDay = prefs.getString(_summaryDayKey) ?? _summaryDay;
      _summaryHour = prefs.getInt(_summaryHourKey) ?? _summaryHour;
      _pushAlerts = prefs.getBool(_pushAlertsKey) ?? _pushAlerts;
      _emailAlerts = prefs.getBool(_emailAlertsKey) ?? _emailAlerts;
      _whatsappAlerts = prefs.getBool(_whatsappAlertsKey) ?? _whatsappAlerts;
      _twoFactor = prefs.getBool(_twoFaKey) ?? _twoFactor;
      _analyticsConsent =
          prefs.getBool(_analyticsConsentKey) ?? _analyticsConsent;
      _isLoaded = true;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, _currency);
    await prefs.setString(_timezoneKey, _timezone);
    await prefs.setString(_languageKey, _language);
    await prefs.setString(_summaryDayKey, _summaryDay);
    await prefs.setInt(_summaryHourKey, _summaryHour);
    await prefs.setBool(_pushAlertsKey, _pushAlerts);
    await prefs.setBool(_emailAlertsKey, _emailAlerts);
    await prefs.setBool(_whatsappAlertsKey, _whatsappAlerts);
    await prefs.setBool(_twoFaKey, _twoFactor);
    await prefs.setBool(_analyticsConsentKey, _analyticsConsent);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This is a mock action. In production this would permanently remove your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete account action triggered (mock).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundCream,
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: !_isLoaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionCard(
                  title: 'Business Preferences',
                  children: [
                    _dropdownTile(
                      label: 'Currency',
                      value: _currency,
                      items: _currencies,
                      onChanged: (value) => setState(() => _currency = value),
                    ),
                    _dropdownTile(
                      label: 'Timezone',
                      value: _timezone,
                      items: _timezones,
                      onChanged: (value) => setState(() => _timezone = value),
                    ),
                    _dropdownTile(
                      label: 'Language',
                      value: _language,
                      items: _languages,
                      onChanged: (value) => setState(() => _language = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  title: 'Notification Channels',
                  children: [
                    _switchTile(
                      label: 'Push notifications',
                      value: _pushAlerts,
                      onChanged: (value) => setState(() => _pushAlerts = value),
                    ),
                    _switchTile(
                      label: 'Email updates',
                      value: _emailAlerts,
                      onChanged: (value) => setState(() => _emailAlerts = value),
                    ),
                    _switchTile(
                      label: 'WhatsApp updates',
                      value: _whatsappAlerts,
                      onChanged: (value) =>
                          setState(() => _whatsappAlerts = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  title: 'Weekly Summary',
                  children: [
                    _dropdownTile(
                      label: 'Summary day',
                      value: _summaryDay,
                      items: _days,
                      onChanged: (value) => setState(() => _summaryDay = value),
                    ),
                    _dropdownTile(
                      label: 'Summary time',
                      value: '${_summaryHour.toString().padLeft(2, '0')}:00',
                      items: List.generate(
                        24,
                        (index) => '${index.toString().padLeft(2, '0')}:00',
                      ),
                      onChanged: (value) => setState(
                        () => _summaryHour = int.tryParse(value.split(':').first) ?? 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  title: 'Security & Privacy',
                  children: [
                    _switchTile(
                      label: 'Two-factor authentication (mock)',
                      value: _twoFactor,
                      onChanged: (value) => setState(() => _twoFactor = value),
                    ),
                    _switchTile(
                      label: 'Allow analytics insights',
                      value: _analyticsConsent,
                      onChanged: (value) =>
                          setState(() => _analyticsConsent = value),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.download_outlined),
                      title: const Text('Export business report'),
                      subtitle:
                          const Text('Download a mock summary of your records'),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report export queued (mock).'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save Settings'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _confirmDeleteAccount,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _dropdownTile({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (next) {
          if (next == null) return;
          onChanged(next);
        },
      ),
    );
  }

  Widget _switchTile({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
      activeThumbColor: kPrimaryGreen,
      activeTrackColor: kPrimaryGreen.withValues(alpha: 0.35),
    );
  }
}
