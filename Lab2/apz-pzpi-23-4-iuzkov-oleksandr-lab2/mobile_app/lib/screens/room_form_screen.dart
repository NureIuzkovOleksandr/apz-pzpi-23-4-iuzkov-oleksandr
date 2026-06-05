import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RoomFormScreen extends StatefulWidget {
  final ApiService api;
  RoomFormScreen({required this.api});

  @override
  _RoomFormScreenState createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _floorController = TextEditingController();
  final _areaController = TextEditingController();
  bool _loading = false;
  bool _isEdit = false;
  int? _roomId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['room'] != null && !_isEdit) {
      final room = args['room'] as Map<String, dynamic>;
      _roomId = room['id'];
      _nameController.text = room['name'] ?? '';
      _descriptionController.text = room['description'] ?? '';
      _floorController.text = room['floor']?.toString() ?? '';
      _areaController.text = room['area']?.toString() ?? '';
      _isEdit = true;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final data = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'floor': _floorController.text.isEmpty ? null : int.tryParse(_floorController.text.trim()),
      'area': _areaController.text.isEmpty ? null : double.tryParse(_areaController.text.trim()),
    };
    final ok = _isEdit
        ? await widget.api.updateRoom(_roomId!, data)
        : await widget.api.createRoom(data) != null;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Room' : 'New Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter room name' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _floorController,
                decoration: InputDecoration(labelText: 'Floor'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _areaController,
                decoration: InputDecoration(labelText: 'Area (m²)'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? CircularProgressIndicator(color: Colors.white) : Text('Save Room'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

