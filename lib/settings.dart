import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;
  final SharedPreferences _prefs;

  ThemeProvider._(this._prefs) {
    // SharedPreferences'dan tema ayarını oku
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
  }

  // Factory constructor ile singleton instance oluştur
  static Future<ThemeProvider> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeProvider._(prefs);
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    // Tema değişikliğini kaydet
    await _prefs.setBool(_themeKey, _isDarkMode);
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
