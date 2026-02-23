import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hervest_ai/models/inventory_model.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
import 'package:hervest_ai/provider/inventory_provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  static const Color kPrimaryGreen = Color(0xFF006B4D);
  static const Color kBackgroundCream = Color(0xFFFDFBF7);

  // Simple mock settings kept active (easy and useful)
  static const String _emailAlertsKey = 'settings_email_alerts';
  static const String _whatsappAlertsKey = 'settings_whatsapp_alerts';
  static const String _channelsLastUpdatedKey =
      'settings_channels_last_updated';
  static const String _lastExportAtKey = 'settings_last_export_at';
  static const String _lastExportTypeKey = 'settings_last_export_type';
  static const String _logoAssetPath = 'assets/hervbypd.png';

  bool _emailAlerts = true;
  bool _whatsappAlerts = false;
  bool _savedEmailAlerts = true;
  bool _savedWhatsappAlerts = false;
  bool _isLoaded = false;
  bool _isSavingChannels = false;
  bool _isExporting = false;
  String _channelsLastUpdatedAt = '';
  String _lastExportAt = '';
  String _lastExportType = '';

  bool get _hasChannelChanges =>
      _emailAlerts != _savedEmailAlerts ||
      _whatsappAlerts != _savedWhatsappAlerts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailAlerts = prefs.getBool(_emailAlertsKey) ?? _emailAlerts;
      _whatsappAlerts = prefs.getBool(_whatsappAlertsKey) ?? _whatsappAlerts;
      _savedEmailAlerts = _emailAlerts;
      _savedWhatsappAlerts = _whatsappAlerts;
      _channelsLastUpdatedAt = prefs.getString(_channelsLastUpdatedKey) ?? '';
      _lastExportAt = prefs.getString(_lastExportAtKey) ?? '';
      _lastExportType = prefs.getString(_lastExportTypeKey) ?? '';
      _isLoaded = true;
    });
  }

  Future<void> _saveChannels() async {
    setState(() => _isSavingChannels = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailAlertsKey, _emailAlerts);
    await prefs.setBool(_whatsappAlertsKey, _whatsappAlerts);
    final updatedAt = DateTime.now().toIso8601String();
    await prefs.setString(_channelsLastUpdatedKey, updatedAt);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _savedEmailAlerts = _emailAlerts;
      _savedWhatsappAlerts = _whatsappAlerts;
      _channelsLastUpdatedAt = updatedAt;
      _isSavingChannels = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification channels updated')),
    );
  }

  void _discardChannelChanges() {
    setState(() {
      _emailAlerts = _savedEmailAlerts;
      _whatsappAlerts = _savedWhatsappAlerts;
    });
  }

  Future<void> _confirmAndSaveChannels() async {
    if (!_hasChannelChanges || _isSavingChannels) return;
    final didConfirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Apply notification changes?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._buildChannelChangeSummary(),
                    const SizedBox(height: 10),
                    Text(
                      'Turning channels off may reduce how quickly you receive low-stock alerts.',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryGreen,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Save changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (didConfirm == true) {
      await _saveChannels();
    }
  }

  List<Widget> _buildChannelChangeSummary() {
    final summary = <Widget>[];
    if (_emailAlerts != _savedEmailAlerts) {
      summary.add(
        Text(
          'Email updates: ${_savedEmailAlerts ? 'On' : 'Off'} -> ${_emailAlerts ? 'On' : 'Off'}',
        ),
      );
    }
    if (_whatsappAlerts != _savedWhatsappAlerts) {
      summary.add(
        Text(
          'WhatsApp updates: ${_savedWhatsappAlerts ? 'On' : 'Off'} -> ${_whatsappAlerts ? 'On' : 'Off'}',
        ),
      );
    }
    return summary;
  }

  Future<void> _exportBusinessReport(ExportReportType reportType) async {
    final inventoryProvider = context.read<InventoryProvider>();
    final appState = context.read<AppStateController>();
    final inventoryItems = inventoryProvider.items.toList(growable: false);
    final criticalCount = inventoryProvider.criticalCount;
    final totalLedgerValue = inventoryProvider.totalLedgerValue;
    final transactions = appState.transactions
        .map<Map<String, dynamic>>((tx) => Map<String, dynamic>.from(tx))
        .toList(growable: false);

    setState(() => _isExporting = true);
    final prefs = await SharedPreferences.getInstance();
    final exportedAt = DateTime.now();
    final reportName = reportType == ExportReportType.inventory
        ? 'Inventory'
        : 'Cashflow';

    try {
      final logo = await _loadAppLogo();
      final bytes = reportType == ExportReportType.inventory
          ? await _buildInventoryReportPdf(
              exportedAt,
              inventoryItems: inventoryItems,
              criticalCount: criticalCount,
              totalLedgerValue: totalLedgerValue,
              logo: logo,
            )
          : await _buildCashflowReportPdf(
              exportedAt,
              transactions: transactions,
              logo: logo,
            );

      final fileName = _buildReportFileName(reportType, exportedAt);
      final savedPath = await _savePdfToAppDocuments(
        bytes: bytes,
        fileName: fileName,
      );

      var shared = false;
      try {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
        shared = true;
      } catch (_) {
        shared = false;
      }

      if (!shared && savedPath == null) {
        throw Exception('Export failed');
      }

      await prefs.setString(_lastExportAtKey, exportedAt.toIso8601String());
      await prefs.setString(_lastExportTypeKey, reportName);

      if (!mounted) return;
      setState(() {
        _lastExportAt = exportedAt.toIso8601String();
        _lastExportType = reportName;
      });

      final message = shared
          ? (savedPath == null
                ? '$reportName PDF exported successfully'
                : '$reportName PDF exported and saved to $savedPath')
          : '$reportName PDF saved to app documents: $savedPath';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to export PDF. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<Uint8List> _buildInventoryReportPdf(
    DateTime exportedAt, {
    required List<InventoryItem> inventoryItems,
    required int criticalCount,
    required double totalLedgerValue,
    required pw.MemoryImage? logo,
  }) async {
    final profilePrefs = await SharedPreferences.getInstance();
    final business = _readProfileValue(
      profilePrefs: profilePrefs,
      key: 'profile_business',
      fallback: 'Business',
    );
    final owner = profilePrefs.getString('profile_full_name') ?? 'Not set';

    final document = pw.Document();
    final items = inventoryItems;

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          ..._buildPdfHeader(logo: logo, title: 'Inventory Snapshot Report'),
          pw.Text('Business: $business'),
          pw.Text('Owner: $owner'),
          pw.Text('Generated: ${_formatExportedAt(exportedAt)}'),
          pw.SizedBox(height: 16),
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 6),
          pw.Bullet(text: 'Total items: ${items.length}'),
          pw.Bullet(text: 'Critical items: $criticalCount'),
          pw.Bullet(
            text:
                'Estimated ledger value: NGN ${totalLedgerValue.toStringAsFixed(2)}',
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Item',
              'Category',
              'Qty',
              'Unit',
              'Expiry',
              'Status',
              'Price',
            ],
            data: items
                .map(
                  (item) => [
                    item.name,
                    item.category,
                    item.quantity.toStringAsFixed(2),
                    item.unit,
                    item.expiryDate?.toIso8601String().split('T').first ?? '-',
                    item.status.name.toUpperCase(),
                    item.purchasePrice?.toStringAsFixed(2) ?? '-',
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              color: PdfColor.fromHex('#FFFFFF'),
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#006B4D'),
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );

    return document.save();
  }

  Future<Uint8List> _buildCashflowReportPdf(
    DateTime exportedAt, {
    required List<Map<String, dynamic>> transactions,
    required pw.MemoryImage? logo,
  }) async {
    final profilePrefs = await SharedPreferences.getInstance();
    final business = _readProfileValue(
      profilePrefs: profilePrefs,
      key: 'profile_business',
      fallback: 'Business',
    );
    final owner = profilePrefs.getString('profile_full_name') ?? 'Not set';

    double income = 0;
    double expense = 0;
    for (final tx in transactions) {
      final rawAmount = (tx['amount'] ?? '').toString();
      final value = _parseCurrencyAmount(rawAmount);
      final type = (tx['type'] ?? '').toString().toLowerCase();
      if (type == 'income') {
        income += value;
      } else {
        expense += value;
      }
    }
    final net = income - expense;

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          ..._buildPdfHeader(logo: logo, title: 'Cashflow Summary Report'),
          pw.Text('Business: $business'),
          pw.Text('Owner: $owner'),
          pw.Text('Generated: ${_formatExportedAt(exportedAt)}'),
          pw.SizedBox(height: 16),
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
          pw.SizedBox(height: 6),
          pw.Bullet(text: 'Total income: NGN ${income.toStringAsFixed(2)}'),
          pw.Bullet(text: 'Total expenses: NGN ${expense.toStringAsFixed(2)}'),
          pw.Bullet(text: 'Net balance: NGN ${net.toStringAsFixed(2)}'),
          pw.Bullet(text: 'Transactions: ${transactions.length}'),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Title', 'Type', 'Amount'],
            data: transactions
                .map(
                  (tx) => [
                    (tx['date'] ?? '').toString(),
                    (tx['title'] ?? '').toString(),
                    (tx['type'] ?? '').toString(),
                    (tx['amount'] ?? '').toString(),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              color: PdfColor.fromHex('#FFFFFF'),
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#006B4D'),
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );

    return document.save();
  }

  double _parseCurrencyAmount(String input) {
    final sanitized = input.replaceAll(RegExp(r'[^0-9\.-]'), '');
    return double.tryParse(sanitized) ?? 0;
  }

  Future<pw.MemoryImage?> _loadAppLogo() async {
    try {
      final logoBytes = await rootBundle.load(_logoAssetPath);
      return pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<String?> _savePdfToAppDocuments({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (kIsWeb) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  List<pw.Widget> _buildPdfHeader({
    required pw.MemoryImage? logo,
    required String title,
  }) {
    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(
              width: 42,
              height: 42,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          if (logo != null) pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#006B4D'),
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 8),
    ];
  }

  String _readProfileValue({
    required SharedPreferences profilePrefs,
    required String key,
    required String fallback,
  }) {
    final value = profilePrefs.getString(key)?.trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String _formatExportedAt(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
  }

  String _buildReportFileName(ExportReportType type, DateTime exportedAt) {
    final reportKey = type == ExportReportType.inventory
        ? 'inventory_report'
        : 'cashflow_report';
    final timestamp = DateFormat(
      'yyyyMMdd_HHmmss',
    ).format(exportedAt.toLocal());
    return '${reportKey}_$timestamp.pdf';
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
                  title: 'Export Business Report',
                  children: [
                    const Text(
                      'Generate a printable PDF for inventory or cashflow data.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    if (_lastExportAt.isNotEmpty)
                      Text(
                        'Last export: $_lastExportType at ${_formatExportedAt(DateTime.parse(_lastExportAt))}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryGreen,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isExporting
                                  ? null
                                  : () => _exportBusinessReport(
                                      ExportReportType.inventory,
                                    ),
                              icon: _isExporting
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.inventory_2_outlined),
                              label: const Text('Inventory PDF'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimaryGreen,
                                side: const BorderSide(color: kPrimaryGreen),
                              ),
                              onPressed: _isExporting
                                  ? null
                                  : () => _exportBusinessReport(
                                      ExportReportType.cashflow,
                                    ),
                              icon: const Icon(Icons.bar_chart_outlined),
                              label: const Text('Cashflow PDF'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  title: 'Update Channels',
                  children: [
                    const Text(
                      'Control if you receive updates via Email or WhatsApp.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Email updates'),
                      value: _emailAlerts,
                      activeThumbColor: kPrimaryGreen,
                      activeTrackColor: kPrimaryGreen.withValues(alpha: 0.35),
                      onChanged: (value) =>
                          setState(() => _emailAlerts = value),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('WhatsApp updates'),
                      value: _whatsappAlerts,
                      activeThumbColor: kPrimaryGreen,
                      activeTrackColor: kPrimaryGreen.withValues(alpha: 0.35),
                      onChanged: (value) =>
                          setState(() => _whatsappAlerts = value),
                    ),
                    Row(
                      children: [
                        _buildStatusPill(
                          label: _emailAlerts
                              ? 'Email verified'
                              : 'Email paused',
                          active: _emailAlerts,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusPill(
                          label: _whatsappAlerts
                              ? 'WhatsApp connected'
                              : 'WhatsApp disconnected',
                          active: _whatsappAlerts,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_channelsLastUpdatedAt.isNotEmpty)
                      Text(
                        'Last updated: ${_formatExportedAt(DateTime.parse(_channelsLastUpdatedAt))}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (_hasChannelChanges)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kPrimaryGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: kPrimaryGreen.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'You have unsaved channel changes.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            TextButton(
                              onPressed: _isSavingChannels
                                  ? null
                                  : _discardChannelChanges,
                              child: const Text('Discard'),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isSavingChannels || !_hasChannelChanges
                            ? null
                            : _confirmAndSaveChannels,
                        child: _isSavingChannels
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Save Channel Preferences'),
                      ),
                    ),
                  ],
                ),

                // Temporarily commented out to avoid repetitive settings UX.
                // _sectionCard(
                //   title: 'Business Preferences',
                //   children: [ ... ],
                // ),
                //
                // _sectionCard(
                //   title: 'Security & Privacy',
                //   children: [ ... ],
                // ),
                //
                // _sectionCard(
                //   title: 'Weekly Summary',
                //   children: [ ... ],
                // ),
              ],
            ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
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

  Widget _buildStatusPill({required String label, required bool active}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? kPrimaryGreen.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? kPrimaryGreen.withValues(alpha: 0.24)
              : Colors.black.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: active ? kPrimaryGreen : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum ExportReportType { inventory, cashflow }
