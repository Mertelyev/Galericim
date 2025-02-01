import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Consumer<ThemeProvider>(
            builder: (context, provider, child) {
              return ListTile(
                leading: Icon(
                  Icons.brightness_6,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Karanlık Mod'),
                subtitle: const Text('Tema rengini değiştir'),
                trailing: Switch(
                  value: provider.isDarkMode,
                  onChanged: (bool value) {
                    provider.toggleTheme();
                  },
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Uygulama Hakkında'),
            subtitle: const Text('Versiyon 1.0.0'),
            onTap: () {
              // Hakkında sayfası için
            },
          ),
        ],
      ),
    );
  }
}
