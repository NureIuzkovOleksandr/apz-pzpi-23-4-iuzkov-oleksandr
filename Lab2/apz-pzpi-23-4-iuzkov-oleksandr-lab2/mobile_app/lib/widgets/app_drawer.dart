import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  final ApiService api;
  final String currentRoute;

  const AppDrawer({required this.api, required this.currentRoute, Key? key}) : super(key: key);

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pop();
    if (route != currentRoute) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF134E6F), const Color(0xFF1FB59A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  child: const Icon(Icons.thermostat, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    loc.translate('appTitle'),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          _DrawerTile(
            icon: Icons.speed,
            title: loc.translate('sensors'),
            selected: currentRoute == '/sensors',
            onTap: () => _navigate(context, '/sensors'),
          ),
          _DrawerTile(
            icon: Icons.meeting_room,
            title: loc.translate('rooms'),
            selected: currentRoute == '/rooms',
            onTap: () => _navigate(context, '/rooms'),
          ),
          _DrawerTile(
            icon: Icons.devices,
            title: loc.translate('devices'),
            selected: currentRoute == '/devices',
            onTap: () => _navigate(context, '/devices'),
          ),
          _DrawerTile(
            icon: Icons.bar_chart,
            title: loc.translate('thresholds'),
            selected: currentRoute == '/thresholds',
            onTap: () => _navigate(context, '/thresholds'),
          ),
          _DrawerTile(
            icon: Icons.notifications,
            title: loc.translate('alerts'),
            selected: currentRoute == '/alerts',
            onTap: () => _navigate(context, '/alerts'),
          ),
          const Divider(),
          _DrawerTile(
            icon: Icons.person,
            title: loc.translate('profile'),
            selected: currentRoute == '/profile',
            onTap: () => _navigate(context, '/profile'),
          ),
          _DrawerTile(
            icon: Icons.settings,
            title: loc.translate('settings'),
            selected: currentRoute == '/settings',
            onTap: () => _navigate(context, '/settings'),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(loc.translate('logout'), style: const TextStyle(color: Colors.black87)),
            onTap: () async {
              Navigator.of(context).pop();
              await api.logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerTile({required this.icon, required this.title, required this.selected, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? const Color(0xFF134E6F) : Colors.black54),
      title: Text(title, style: TextStyle(color: selected ? const Color(0xFF134E6F) : Colors.black87, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      selected: selected,
      selectedTileColor: const Color(0xFFE8F7F2),
      onTap: onTap,
    );
  }
}

