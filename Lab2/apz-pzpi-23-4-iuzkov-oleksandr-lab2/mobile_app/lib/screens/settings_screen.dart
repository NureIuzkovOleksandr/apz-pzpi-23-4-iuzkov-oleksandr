import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  final ApiService api;
  SettingsScreen({required this.api});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _languageCode = 'en';

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppState>(context, listen: false);
    _languageCode = state.locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(api: widget.api, currentRoute: '/settings'),
      appBar: AppBar(title: Text(AppLocalizations.of(context).translate('settings'))),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEFF6FF), Color(0xFFDDEBFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('userSettings'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _languageCode,
                        decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('language')),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'uk', child: Text('Українська')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _languageCode = value;
                          });
                          Provider.of<AppState>(context, listen: false).setLocale(Locale(value));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await widget.api.logout();
                  Navigator.of(context).pushReplacementNamed('/');
                },
                child: Text(AppLocalizations.of(context).translate('logout')),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

