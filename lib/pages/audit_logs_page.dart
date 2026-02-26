import 'package:flutter/material.dart';
import 'package:hervest_ai/provider/app_state_controller_mock.dart';
import 'package:provider/provider.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppStateController>().loadAuditLogsFromBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs')),
      body: state.auditLogs.isEmpty
          ? const Center(child: Text('No audit logs or access denied.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.auditLogs.length,
              itemBuilder: (context, index) {
                final row = state.auditLogs[index];
                final action = row.action;
                final actor = row.userId;
                final createdAt = row.timestamp.toIso8601String();
                return Card(
                  child: ListTile(
                    title: Text(action),
                    subtitle: Text('$actor • $createdAt'),
                  ),
                );
              },
            ),
    );
  }
}
