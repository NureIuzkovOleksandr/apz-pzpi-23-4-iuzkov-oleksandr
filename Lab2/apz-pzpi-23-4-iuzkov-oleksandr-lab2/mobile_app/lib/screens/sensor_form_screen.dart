import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SensorFormScreen extends StatefulWidget {
  final ApiService api;
  SensorFormScreen({required this.api});

  @override
  _SensorFormScreenState createState() => _SensorFormScreenState();
}

class _SensorFormScreenState extends State<SensorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _sensorType = 'temperature';
  String _status = 'active';
  int? _roomId;
  int? _selectedDeviceId;
  bool _loading = true;
  bool _saving = false;
  bool _isEdit = false;
  int? _sensorId;
  List<dynamic> _rooms = [];
  List<dynamic> _devices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['sensor'] != null) {
        final sensor = args['sensor'] as Map<String, dynamic>;
        _sensorId = sensor['id'];
        _nameController.text = sensor['name'] ?? '';
        _sensorType = sensor['sensor_type'] ?? 'temperature';
        _status = sensor['status'] ?? 'active';
        _roomId = sensor['room_id'];
        _isEdit = true;
      }
      await _loadRooms();
      await _loadDevices();
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load error: $e')));
    }
  }

  Future<void> _loadRooms() async {
    final rooms = await widget.api.getRooms();
    if (mounted) {
      setState(() {
        _rooms = rooms;
        _roomId ??= rooms.isNotEmpty ? rooms.first['id'] as int : null;
      });
    }
  }

  Future<void> _loadDevices() async {
    final devices = await widget.api.getClimateDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        if (_devices.isNotEmpty && _selectedDeviceId == null) {
          _selectedDeviceId = _devices.first['id'] as int;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a device')),
      );
      return;
    }

    setState(() => _saving = true);

    try {

      final selectedDevice = _devices.firstWhere((d) => d['id'] == _selectedDeviceId);
      final deviceId = selectedDevice['device_id']?.toString();

      if (deviceId == null || deviceId.isEmpty) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected device has no device_id')),
        );
        return;
      }

      final endpoint = _isEdit ? '/api/sensors/${_sensorId}' : '/api/sensors';
      final method = _isEdit ? 'PUT' : 'POST';
      final data = {
        'name': _nameController.text.trim(),
        'device_id': deviceId,
        'sensor_type': _sensorType,
        if (!_isEdit) 'room_id': _roomId,
        if (_isEdit) 'status': _status,
      };

      final resp = await widget.api.requestWithResponse(method, endpoint, data).timeout(
        const Duration(seconds: 10),
        onTimeout: () => {'status': 0, 'body': 'Request timeout'},
      );

      print('RESP STATUS: ${resp['status']}');
      print('RESP BODY: ${resp['body']}');

      setState(() => _saving = false);

      if (resp['status'] is int && (resp['status'] as int) >= 200 && (resp['status'] as int) < 300) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final body = resp['body'];
        final msg = body is String ? body : (body is Map ? (body['detail'] ?? body['error'] ?? body).toString() : body.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Save failed: ${msg}')),
          );
        }
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Sensor' : 'New Sensor')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Sensor Name'),
                      validator: (value) => value == null || value.isEmpty ? 'Enter sensor name' : null,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _selectedDeviceId,
                      decoration: InputDecoration(labelText: 'Device'),
                      items: _devices
                          .map((d) => DropdownMenuItem<int>(
                                value: d['id'] as int,
                                child: Text(d['name']?.toString() ?? 'Unknown Device'),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedDeviceId = value),
                      validator: (value) => value == null ? 'Select a device' : null,
                    ),
                    SizedBox(height: 12),
                    if (!_isEdit) ...[
                      DropdownButtonFormField<int>(
                        value: _roomId,
                        items: _rooms
                            .map((room) => DropdownMenuItem<int>(
                                  value: room['id'] as int,
                                  child: Text(room['name'] ?? 'Room'),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _roomId = value),
                        decoration: InputDecoration(labelText: 'Room'),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _sensorType,
                        items: ['temperature', 'humidity', 'combined']
                            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (value) => setState(() => _sensorType = value ?? 'temperature'),
                        decoration: InputDecoration(labelText: 'Sensor type'),
                      ),
                      SizedBox(height: 12),
                    ],
                    if (_isEdit) ...[
                      DropdownButtonFormField<String>(
                        value: _status,
                        items: ['active', 'inactive', 'error']
                            .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                            .toList(),
                        onChanged: (value) => setState(() => _status = value ?? 'active'),
                        decoration: InputDecoration(labelText: 'Status'),
                      ),
                      SizedBox(height: 12),
                    ],
                    ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving ? CircularProgressIndicator(color: Colors.white) : Text('Save Sensor'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

