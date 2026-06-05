import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class AlertFormScreen extends StatefulWidget {
  final ApiService api;
  AlertFormScreen({required this.api});

  @override
  _AlertFormScreenState createState() => _AlertFormScreenState();
}

class _AlertFormScreenState extends State<AlertFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = '';
  String _severity = '';
  String _message = '';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final result = await widget.api.createAlert({
      'alert_type': _type,
      'severity': _severity,
      'message': _message,
    });
    if (result != null) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('saveFailed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('newAlert'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: loc.translate('alertType')),
                validator: (value) => value == null || value.isEmpty ? loc.translate('requiredField') : null,
                onSaved: (value) => _type = value ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: loc.translate('severity')),
                validator: (value) => value == null || value.isEmpty ? loc.translate('requiredField') : null,
                onSaved: (value) => _severity = value ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: loc.translate('message')),
                validator: (value) => value == null || value.isEmpty ? loc.translate('requiredField') : null,
                onSaved: (value) => _message = value ?? '',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Text(loc.translate('save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

