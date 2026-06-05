import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_drawer.dart';

class RoomsScreen extends StatefulWidget {
  final ApiService api;
  RoomsScreen({required this.api});

  @override
  _RoomsScreenState createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  bool _loading = true;
  List<dynamic> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _loading = true);
    final rooms = await widget.api.getRooms();
    setState(() {
      _rooms = rooms;
      _loading = false;
    });
  }

  Future<void> _deleteRoom(int id) async {
    final ok = await widget.api.deleteRoom(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Room deleted' : 'Delete failed')));
    if (ok) _loadRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(api: widget.api, currentRoute: '/rooms'),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('rooms')),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRooms,
              child: ListView.builder(
                itemCount: _rooms.length,
                itemBuilder: (context, index) {
                  final room = _rooms[index];
                  return ListTile(
                    title: Text(room['name'] ?? 'Room'),
                    subtitle: Text('Floor: ${room['floor'] ?? '-'}  Area: ${room['area'] ?? '-'}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline),
                      onPressed: () => _deleteRoom(room['id']),
                    ),
                    onTap: () => Navigator.of(context).pushNamed('/room_form', arguments: {'room': room}).then((_) => _loadRooms()),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.of(context).pushNamed('/room_form').then((_) => _loadRooms()),
      ),
    );
  }
}

