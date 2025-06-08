import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flutter/foundation.dart'; // kIsWeb için import edildi
import 'package:flutter_localizations/flutter_localizations.dart'; // Bunu ekleyin
import './theme.dart';
import './trends.dart';
import './statistic.dart';
import './settings.dart';
import './carlist.dart';
import './services/logging_service.dart';

void main() async {
  final logger = LoggingService();
  
  try {
    logger.info('Application starting up');
    WidgetsFlutterBinding.ensureInitialized(); // Flutter binding'i başlat
    
    // Web platformunda SQLite'ı başlat
    if (kIsWeb) {
      logger.info('Initializing database for web platform');
      databaseFactory = databaseFactoryFfiWeb;
      // Web worker'ı başlat
      sqfliteFfiInit();
    } else {
      logger.info('Initializing database for native platform');
      // Diğer platformlarda SQLite'ı başlat
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Tema provider'ı oluştur
    logger.info('Creating theme provider');
    final themeProvider = await ThemeProvider.create();
    logger.info('Application initialization completed successfully');

    runApp(
      ChangeNotifierProvider(
        create: (_) => themeProvider,
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    logger.error('Failed to initialize application', error: e, stackTrace: stackTrace);
    // Still try to run the app with default theme
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Galericim',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          // Türkçe dil desteği için ekleyin
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('tr', 'TR'), // Türkçe
          ],
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const TrendsPage(),
    const StatisticPage(),
    const CarListPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4), // Alt boşluk eklendi
            child: NavigationBar(
              elevation: 0,
              height: 60, // 72'den 60'a düşürüldü
              backgroundColor: Colors.transparent,
              indicatorColor: Theme.of(context).colorScheme.primaryContainer,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              animationDuration: const Duration(milliseconds: 700),
              destinations: [
                _buildNavDestination(
                  index: 0,
                  label: 'Trendler',
                  icon: Icons.trending_up_outlined,
                  selectedIcon: Icons.trending_up,
                ),
                _buildNavDestination(
                  index: 1,
                  label: 'İstatistikler',
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart,
                ),
                _buildNavDestination(
                  index: 2,
                  label: 'Araçlar',
                  icon: Icons.directions_car_outlined,
                  selectedIcon: Icons.directions_car,
                ),
                _buildNavDestination(
                  index: 3,
                  label: 'Ayarlar',
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    final isSelected = _selectedIndex == index;
    return NavigationDestination(
      icon: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurfaceVariant,
        size: 22, // 24'ten 22'ye düşürüldü
      ),
      selectedIcon: Icon(
        selectedIcon,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        size: 22, // 24'ten 22'ye düşürüldü
      ),
      label: label,
    );
  }
}
