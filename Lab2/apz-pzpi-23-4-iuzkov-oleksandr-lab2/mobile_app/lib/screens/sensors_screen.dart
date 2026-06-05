import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_drawer.dart';

class SensorsScreen extends StatefulWidget {
  final ApiService api;
  SensorsScreen({required this.api});

  @override
  _SensorsScreenState createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  bool _loading = true;
  List<dynamic> _sensors = [];

  @override
  void initState() {
    super.initState();
    _loadSensors();
  }

  Future<void> _loadSensors() async {
    setState(() {
      _loading = true;
    });
    final sensors = await widget.api.getSensors();
    setState(() {
      _sensors = sensors;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(api: widget.api, currentRoute: '/sensors'),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('sensors')),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFDDEBFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: RefreshIndicator(
                onRefresh: _loadSensors,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  itemCount: _sensors.length,
                  itemBuilder: (context, index) {
                    final sensor = _sensors[index];
                    final status = sensor['status'] ?? 'unknown';
                    final statusColor = status.toString().toLowerCase() == 'online' ? Color(0xFF38C6C0) : Colors.orange;
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0A57D5),
                          child: const Icon(Icons.speed, color: Colors.white),
                        ),
                        title: Text(sensor['name'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${AppLocalizations.of(context).translate('status')}: $status',
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF0A57D5)),
                          onPressed: () => Navigator.of(context).pushNamed('/sensor_form', arguments: {'sensor': sensor}).then((_) => _loadSensors()),
                        ),
                        onTap: () => Navigator.of(context).pushNamed('/sensor_detail', arguments: {'sensor': sensor}),
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0A57D5),
        child: const Icon(Icons.add),
        onPressed: () => Navigator.of(context).pushNamed('/sensor_form').then((_) => _loadSensors()),
      ),
    );
  }
}

