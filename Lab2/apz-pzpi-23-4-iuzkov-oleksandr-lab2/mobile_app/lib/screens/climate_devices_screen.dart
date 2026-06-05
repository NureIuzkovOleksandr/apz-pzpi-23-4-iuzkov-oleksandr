import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_drawer.dart';

class ClimateDevicesScreen extends StatefulWidget {
  final ApiService api;
  ClimateDevicesScreen({required this.api});

  @override
  _ClimateDevicesScreenState createState() => _ClimateDevicesScreenState();
}

class _ClimateDevicesScreenState extends State<ClimateDevicesScreen> {
  bool _loading = true;
  List<dynamic> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _loading = true);
    final devices = await widget.api.getClimateDevices();
    setState(() {
      _devices = devices;
      _loading = false;
    });
  }

  Future<void> _send(int deviceId, String cmd) async {
    final ok = await widget.api.sendDeviceCommand(deviceId, cmd);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'OK' : 'Failed')));
    if (ok) _loadDevices();
  }

  Future<void> _deleteDevice(int id) async {
    final ok = await widget.api.deleteClimateDevice(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Device deleted' : 'Delete failed')));
    if (ok) _loadDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(api: widget.api, currentRoute: '/devices'),
      appBar: AppBar(title: Text(AppLocalizations.of(context).translate('devices'))),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDevices,
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final d = _devices[index];
                  return ListTile(
                    title: Text(d['name'] ?? 'Device'),
                    subtitle: Text('Type: ${d['device_type'] ?? '-'}  Status: ${d['status'] ?? '-'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.power_settings_new, color: Colors.green),
                          onPressed: () => _send(d['id'], 'turn_on'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.power_off, color: Colors.red),
                          onPressed: () => _send(d['id'], 'turn_off'),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).pushNamed('/device_form', arguments: {'device': d}).then((_) => _loadDevices()),
                    onLongPress: () => _deleteDevice(d['id']),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed('/device_form').then((_) => _loadDevices()),
        child: const Icon(Icons.add),
        tooltip: AppLocalizations.of(context).translate('addDevice'),
      ),
    );
  }
}