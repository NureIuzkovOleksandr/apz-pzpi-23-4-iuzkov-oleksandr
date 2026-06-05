import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SensorDetailScreen extends StatefulWidget {
  final ApiService api;
  SensorDetailScreen({required this.api});

  @override
  _SensorDetailScreenState createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  bool _loading = true;
  List<dynamic> _readings = [];
  Map<String, dynamic>? _sensor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    _sensor = args?['sensor'];
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    if (_sensor == null) return;
    setState(() {
      _loading = true;
    });
    final readings = await widget.api.getSensorReadings(_sensor!['id']);
    setState(() {
      _readings = readings;
      _loading = false;
    });
  }

  Future<void> _sendCommand() async {

    final deviceId = _sensor?['device_id_map'] ?? _sensor?['linked_device_id'];
    if (deviceId == null) return;
    final ok = await widget.api.sendDeviceCommand(deviceId, 'turn_on');
    final snack = ok ? 'Command sent' : 'Command failed';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snack)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_sensor?['name'] ?? 'Sensor')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status: ${_sensor?['status'] ?? 'unknown'}'),
                      ElevatedButton(onPressed: _sendCommand, child: Text('Turn device on')),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _readings.length,
                    itemBuilder: (context, index) {
                      final r = _readings[index];
                      return ListTile(
                        title: Text('Temp: ${r['temperature'] ?? '-'}  Hum: ${r['humidity'] ?? '-'}'),
                        subtitle: Text(r['timestamp'] ?? ''),
                      );
                    },
                  ),
                )
              ],
            ),
    );
  }
}

