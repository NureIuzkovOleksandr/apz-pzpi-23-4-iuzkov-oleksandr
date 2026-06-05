import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class ThresholdFormScreen extends StatefulWidget {
  final ApiService api;
  ThresholdFormScreen({required this.api});

  @override
  _ThresholdFormScreenState createState() => _ThresholdFormScreenState();
}

class _ThresholdFormScreenState extends State<ThresholdFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _minTempController = TextEditingController();
  final _maxTempController = TextEditingController();
  final _minHumidityController = TextEditingController();
  final _maxHumidityController = TextEditingController();

  List<dynamic> _rooms = [];
  int? _roomId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final rooms = await widget.api.getRooms();
    setState(() {
      _rooms = rooms;
      _roomId = rooms.isNotEmpty ? rooms.first['id'] as int : null;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room')),
      );
      return;
    }

    setState(() => _saving = true);

    final minTemp = double.tryParse(_minTempController.text.trim());
    final maxTemp = double.tryParse(_maxTempController.text.trim());
    final minHumidity = double.tryParse(_minHumidityController.text.trim());
    final maxHumidity = double.tryParse(_maxHumidityController.text.trim());


    if (minTemp == null && maxTemp == null && minHumidity == null && maxHumidity == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set at least one threshold')),
      );
      return;
    }

    final payload = <String, dynamic>{
      'room_id': _roomId!,
    };


    if (minTemp != null) {
      payload['min_temperature'] = minTemp;
    }
    if (maxTemp != null) {
      payload['max_temperature'] = maxTemp;
    }
    if (minHumidity != null) {
      payload['min_humidity'] = minHumidity;
    }
    if (maxHumidity != null) {
      payload['max_humidity'] = maxHumidity;
    }

    try {
      final resp = await widget.api.requestWithResponse('POST', '/api/climate-thresholds', payload).timeout(
        const Duration(seconds: 10),
        onTimeout: () => {'status': 0, 'body': 'Request timeout'},
      );

      print('Response status: ${resp['status']}');
      print('Response body: ${resp['body']}');

      setState(() => _saving = false);

      if (resp['status'] is int && (resp['status'] as int) >= 200 && (resp['status'] as int) < 300) {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final body = resp['body'];
        String msg;
        if (body is String) {
          msg = body;
        } else if (body is Map) {
          msg = body['detail'] ?? body['error'] ?? body.toString();
        } else {
          msg = body.toString();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Save failed: $msg')),
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
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('newThreshold'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _roomId,
                      decoration: InputDecoration(labelText: loc.translate('room')),
                      items: _rooms
                          .map((r) => DropdownMenuItem<int>(
                            value: r['id'] as int,
                            child: Text(r['name'] ?? loc.translate('room')),
                          ))
                          .toList(),
                      onChanged: (v) => setState(() => _roomId = v),
                      validator: (v) => v == null ? loc.translate('requiredField') : null,
                    ),
                    const SizedBox(height: 24),


                    Text(
                      'Temperature (°C)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minTempController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: InputDecoration(
                              labelText: 'Min',
                              hintText: 'e.g., 18',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              if (double.tryParse(value) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _maxTempController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: InputDecoration(
                              labelText: 'Max',
                              hintText: 'e.g., 26',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              if (double.tryParse(value) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),


                    Text(
                      'Humidity (%)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minHumidityController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Min',
                              hintText: 'e.g., 30',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final val = double.tryParse(value);
                              if (val == null) return 'Invalid number';
                              if (val < 0 || val > 100) return 'Must be 0-100';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _maxHumidityController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Max',
                              hintText: 'e.g., 60',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final val = double.tryParse(value);
                              if (val == null) return 'Invalid number';
                              if (val < 0 || val > 100) return 'Must be 0-100';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(loc.translate('save')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _minTempController.dispose();
    _maxTempController.dispose();
    _minHumidityController.dispose();
    _maxHumidityController.dispose();
    super.dispose();
  }
}

