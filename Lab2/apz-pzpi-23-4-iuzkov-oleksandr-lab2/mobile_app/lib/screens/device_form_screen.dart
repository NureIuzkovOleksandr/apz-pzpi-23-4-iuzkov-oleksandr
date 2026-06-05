import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class DeviceFormScreen extends StatefulWidget {
  final ApiService api;
  DeviceFormScreen({required this.api});

  @override
  _DeviceFormScreenState createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends State<DeviceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _powerController = TextEditingController();
  String _deviceType = 'air_conditioner';
  String _status = 'on';
  int? _roomId;
  bool _loading = true;
  bool _saving = false;
  bool _isEdit = false;
  int? _deviceIdValue;
  String? _deviceIdentifier;
  List<dynamic> _rooms = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['device'] != null && !_isEdit) {
      final device = args['device'] as Map<String, dynamic>;
      _deviceIdValue = device['id'];
      _nameController.text = device['name'] ?? '';
      _deviceIdentifier = device['device_id']?.toString();
      _deviceType = device['device_type'] ?? 'air_conditioner';
      _status = device['status'] ?? 'on';
      _powerController.text = device['power_consumption']?.toString() ?? '';
      _roomId = device['room_id'];
      _isEdit = true;
    }
    if (_rooms.isEmpty) {
      _loadRooms();
    }
  }

  Future<void> _loadRooms() async {
    final rooms = await widget.api.getRooms();
    setState(() {
      _rooms = rooms;
      _loading = false;
      _roomId ??= rooms.isNotEmpty ? rooms.first['id'] as int : null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final Map<String, dynamic> data = {
      'name': _nameController.text.trim(),
      'device_type': _deviceType,
      'power_consumption': _powerController.text.isEmpty ? null : double.tryParse(_powerController.text.trim()),
      if (!_isEdit) 'room_id': _roomId,
      if (_isEdit) 'status': _status,
    };


    if (!_isEdit) {
      final idToSend = (_deviceIdentifier != null && _deviceIdentifier!.isNotEmpty)
          ? _deviceIdentifier
          : 'app-gen-${DateTime.now().millisecondsSinceEpoch}';
      data['device_id'] = idToSend;
    } else {
      if (_deviceIdentifier != null && _deviceIdentifier!.isNotEmpty) data['device_id'] = _deviceIdentifier;
    }
    if (_isEdit) {
      final ok = await widget.api.updateClimateDevice(_deviceIdValue!, data);
      setState(() => _saving = false);
      if (ok) Navigator.of(context).pop(true);
      else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed')));
      return;
    }

    final resp = await widget.api.postWithResponse('/api/climate-devices', data);
    setState(() => _saving = false);
    if (resp['status'] is int && (resp['status'] as int) >= 200 && (resp['status'] as int) < 300) {
      Navigator.of(context).pop(true);
    } else {
      final body = resp['body'];
      final msg = body is String ? body : (body is Map ? (body['detail'] ?? body['error'] ?? body).toString() : body.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: ${msg}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final typeOptions = {
      'air_conditioner': loc.translate('airConditioner'),
      'heater': loc.translate('heater'),
      'humidifier': loc.translate('humidifier'),
      'dehumidifier': loc.translate('dehumidifier'),
    };

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? loc.translate('saveDevice') : loc.translate('addDevice'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: loc.translate('deviceName')),
                      validator: (value) => value == null || value.isEmpty ? loc.translate('requiredField') : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _roomId,
                      items: _rooms
                          .map((room) => DropdownMenuItem<int>(
                                value: room['id'] as int,
                                child: Text(room['name'] ?? loc.translate('room')),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _roomId = value),
                      decoration: InputDecoration(labelText: loc.translate('room')),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _deviceType,
                      items: typeOptions.entries
                          .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                          .toList(),
                      onChanged: (value) => setState(() => _deviceType = value ?? 'air_conditioner'),
                      decoration: InputDecoration(labelText: loc.translate('deviceType')),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _powerController,
                      decoration: InputDecoration(labelText: loc.translate('powerConsumption')),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    if (_isEdit) ...[
                      DropdownButtonFormField<String>(
                        value: _status,
                        items: ['on', 'off', 'error']
                            .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                            .toList(),
                        onChanged: (value) => setState(() => _status = value ?? 'on'),
                        decoration: InputDecoration(labelText: loc.translate('status')),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving ? const CircularProgressIndicator(color: Colors.white) : Text(loc.translate('saveDevice')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

