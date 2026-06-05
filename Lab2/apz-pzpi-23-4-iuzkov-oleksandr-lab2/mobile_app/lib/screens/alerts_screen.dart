import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_drawer.dart';

class AlertsScreen extends StatefulWidget {
  final ApiService api;
  AlertsScreen({required this.api});

  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _loading = true;
  List<dynamic> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    final alerts = await widget.api.getAlerts();
    setState(() {
      _alerts = alerts;
      _loading = false;
    });
  }

  Future<void> _markRead(int id) async {
    final ok = await widget.api.markAlertRead(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? AppLocalizations.of(context).translate('markRead') : 'Failed')));
    if (ok) _loadAlerts();
  }

  Future<void> _delete(int id) async {
    final ok = await widget.api.deleteAlert(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? AppLocalizations.of(context).translate('delete') : 'Failed')));
    if (ok) _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      drawer: AppDrawer(api: widget.api, currentRoute: '/alerts'),
      appBar: AppBar(title: Text(loc.translate('alerts'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFDDEBFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: RefreshIndicator(
                onRefresh: _loadAlerts,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    final isRead = alert['is_read'] == true;
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        title: Text(alert['message'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              Chip(
                                label: Text(alert['alert_type'] ?? ''),
                                backgroundColor: const Color(0xFF0A57D5).withOpacity(0.12),
                              ),
                              Chip(
                                label: Text(alert['severity'] ?? ''),
                                backgroundColor: const Color(0xFF38C6C0).withOpacity(0.12),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isRead)
                              IconButton(
                                icon: const Icon(Icons.mark_email_read, color: Color(0xFF0A57D5)),
                                onPressed: () => _markRead(alert['id']),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _delete(alert['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: null,
    );
  }
}

