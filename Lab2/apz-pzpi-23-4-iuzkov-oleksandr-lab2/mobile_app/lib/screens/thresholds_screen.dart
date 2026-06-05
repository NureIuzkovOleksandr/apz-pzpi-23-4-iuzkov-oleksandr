import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_drawer.dart';

class ThresholdsScreen extends StatefulWidget {
  final ApiService api;
  ThresholdsScreen({required this.api});

  @override
  _ThresholdsScreenState createState() => _ThresholdsScreenState();
}

class _ThresholdsScreenState extends State<ThresholdsScreen> {
  bool _loading = true;
  List<dynamic> _thresholds = [];
  Map<int, String> _roomNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);


    final rooms = await widget.api.getRooms();
    final roomMap = <int, String>{};
    for (final room in rooms) {
      roomMap[room['id'] as int] = room['name'] ?? 'Room';
    }


    final thresholds = await widget.api.getClimateThresholds();

    setState(() {
      _thresholds = thresholds;
      _roomNames = roomMap;
      _loading = false;
    });
  }

  Future<void> _deleteThreshold(int id) async {
    final ok = await widget.api.deleteClimateThreshold(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? AppLocalizations.of(context).translate('deleteSuccess')
              : AppLocalizations.of(context).translate('deleteFailed'),
        ),
      ),
    );
    if (ok) _loadData();
  }

  String _formatThresholdData(Map<String, dynamic> threshold) {
    final parts = <String>[];

    if (threshold['min_temperature'] != null) {
      parts.add('Min Temp: ${threshold['min_temperature']}°C');
    }
    if (threshold['max_temperature'] != null) {
      parts.add('Max Temp: ${threshold['max_temperature']}°C');
    }
    if (threshold['min_humidity'] != null) {
      parts.add('Min Humidity: ${threshold['min_humidity']}%');
    }
    if (threshold['max_humidity'] != null) {
      parts.add('Max Humidity: ${threshold['max_humidity']}%');
    }

    return parts.isNotEmpty ? parts.join('\n') : 'No thresholds set';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      drawer: AppDrawer(api: widget.api, currentRoute: '/thresholds'),
      appBar: AppBar(title: Text(loc.translate('thresholds'))),
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
              child: _thresholds.isEmpty
                  ? Center(
                      child: Text(
                        loc.translate('noData'),
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        itemCount: _thresholds.length,
                        itemBuilder: (context, index) {
                          final item = _thresholds[index] as Map<String, dynamic>;
                          final roomId = item['room_id'] as int;
                          final roomName = _roomNames[roomId] ?? 'Room #$roomId';
                          final thresholdText = _formatThresholdData(item);

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              title: Text(
                                roomName,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                thresholdText,
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _deleteThreshold(item['id'] as int),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.of(context).pushNamed('/threshold_form').then((value) {
          if (value == true) _loadData();
        }),
      ),
    );
  }
}

