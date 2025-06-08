import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';
import 'services/logging_service.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart';
import 'utils/data_export.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;
  final SharedPreferences? _prefs;

  ThemeProvider._(this._prefs) {
    // SharedPreferences'dan tema ayarını oku
    _isDarkMode = _prefs?.getBool(_themeKey) ?? false;
  }

  // Default constructor for error cases
  ThemeProvider() : _prefs = null;

  // Factory constructor ile singleton instance oluştur
  static Future<ThemeProvider> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeProvider._(prefs);
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    // Tema değişikliğini kaydet (eğer prefs mevcutsa)
    await _prefs?.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final dbHelper = DBHelper();
  final logger = LoggingService();
  final backupService = BackupService();
  final notificationService = NotificationService();
  bool isExporting = false;
  bool isBackingUp = false;
  bool isRestoring = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(        children: [
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
          ),          const Divider(),
          
          // Backup & Restore Section
          ListTile(
            leading: Icon(
              Icons.backup,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Veri Yedekleme'),
            subtitle: const Text('Tüm araç verilerini yedekle'),
            trailing: isBackingUp ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ) : null,
            onTap: isBackingUp ? null : _createBackup,
          ),
          
          ListTile(
            leading: Icon(
              Icons.restore,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Veri Geri Yükleme'),
            subtitle: const Text('Yedek dosyasından veri geri yükle'),
            trailing: isRestoring ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ) : null,
            onTap: isRestoring ? null : _showRestoreDialog,
          ),
          
          const Divider(),
          
          // Data Export Section
          ListTile(
            leading: Icon(
              Icons.download,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Verileri Dışa Aktar'),
            subtitle: const Text('Araç verilerini CSV formatında dışa aktar'),
            trailing: isExporting ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ) : null,
            onTap: isExporting ? null : _exportDataToCsv,
          ),
          
          ListTile(
            leading: Icon(
              Icons.analytics,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('İstatistik Raporu'),
            subtitle: const Text('İstatistik raporunu panoya kopyala'),
            onTap: _exportStatisticsReport,
          ),
          
          ListTile(
            leading: Icon(
              Icons.bug_report,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Hata Logları'),
            subtitle: const Text('Uygulama loglarını görüntüle'),
            onTap: _showLogDialog,
          ),
          
          const Divider(),
          
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Uygulama Hakkında'),
            subtitle: const Text('Versiyon 1.0.0'),
            onTap: _showAboutDialog,
          ),
        ],
      ),
    );
  }

  Future<void> _exportDataToCsv() async {
    setState(() {
      isExporting = true;
    });

    try {
      logger.info('Starting data export to CSV', tag: 'Settings');
      final cars = await dbHelper.getCars();
      final csvContent = DataExportService.exportToCsv(cars);
      
      await DataExportService.copyToClipboard(csvContent);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${cars.length} araç verisi panoya kopyalandı (CSV format)'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            action: SnackBarAction(
              label: 'Tamam',
              onPressed: () {},
            ),
          ),
        );
      }
      
      logger.info('Successfully exported ${cars.length} cars to CSV', tag: 'Settings');
    } catch (e, stackTrace) {
      logger.error('Failed to export data to CSV', tag: 'Settings', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri dışa aktarılırken hata oluştu: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        isExporting = false;
      });
    }
  }

  Future<void> _exportStatisticsReport() async {
    try {
      logger.info('Exporting statistics report', tag: 'Settings');
      final cars = await dbHelper.getCars();
      final reportContent = DataExportService.generateStatisticsSummary(cars);
      
      await DataExportService.copyToClipboard(reportContent);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('İstatistik raporu panoya kopyalandı'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
      
      logger.info('Successfully exported statistics report', tag: 'Settings');
    } catch (e, stackTrace) {
      logger.error('Failed to export statistics report', tag: 'Settings', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapor oluşturulurken hata oluştu: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showLogDialog() {
    final logs = logger.getLogs(minLevel: LogLevel.warning);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uygulama Logları'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: logs.isEmpty
              ? const Center(
                  child: Text('Henüz log kaydı yok'),
                )
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getLogLevelColor(log.level),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.level.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  log.tag,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  log.timestamp.toString().substring(11, 19),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(log.message),
                            if (log.error != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Error: ${log.error}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final logText = logger.exportLogsAsText(minLevel: LogLevel.warning);
              DataExportService.copyToClipboard(logText);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Loglar panoya kopyalandı')),
              );
            },
            child: const Text('Kopyala'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Color _getLogLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.purple;
    }
  }
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Galericim',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.directions_car,
        size: 48,
      ),
      children: [
        const Text('Araç galeri yönetim uygulaması'),
        const SizedBox(height: 16),
        const Text('Özellikler:'),
        const Text('• Araç ekleme ve düzenleme'),
        const Text('• Satış takibi'),
        const Text('• İstatistik raporları'),
        const Text('• Trend analizleri'),
        const Text('• Veri dışa aktarma'),
        const Text('• Veri yedekleme ve geri yükleme'),
        const Text('• Gelişmiş arama ve filtreleme'),
      ],
    );
  }
  Future<void> _createBackup() async {
    setState(() {
      isBackingUp = true;
    });

    try {
      logger.info('Starting backup creation', tag: 'Settings');
      final backupData = await BackupService.exportBackupAsJson();
      
      await Clipboard.setData(ClipboardData(text: backupData));
      
      if (mounted) {
        notificationService.showSuccess(
          'Yedek verisi panoya kopyalandı. Güvenli bir yere kaydedin.',
          title: 'Yedekleme Başarılı',
        );
      }
      
      logger.info('Backup creation completed successfully', tag: 'Settings');
    } catch (e, stackTrace) {
      logger.error('Failed to create backup', tag: 'Settings', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        notificationService.showError(
          'Yedek oluşturulurken hata oluştu: $e',
          title: 'Yedekleme Hatası',
        );
      }
    } finally {
      setState(() {
        isBackingUp = false;
      });
    }
  }

  void _showRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => _RestoreDialog(
        backupService: backupService,
        notificationService: notificationService,
        logger: logger,
        onRestoreStarted: () => setState(() => isRestoring = true),
        onRestoreCompleted: () => setState(() => isRestoring = false),
      ),
    );
  }
}

class _RestoreDialog extends StatefulWidget {
  final BackupService backupService;
  final NotificationService notificationService;
  final LoggingService logger;
  final VoidCallback onRestoreStarted;
  final VoidCallback onRestoreCompleted;

  const _RestoreDialog({
    required this.backupService,
    required this.notificationService,
    required this.logger,
    required this.onRestoreStarted,
    required this.onRestoreCompleted,
  });

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  final _controller = TextEditingController();
  RestoreMode _selectedMode = RestoreMode.merge;
  bool _isRestoring = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Veri Geri Yükleme'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yedek verisi (JSON formatında):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Yedek verisi buraya yapıştırın...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Geri yükleme modu:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                RadioListTile<RestoreMode>(
                  value: RestoreMode.merge,
                  groupValue: _selectedMode,
                  onChanged: (value) => setState(() => _selectedMode = value!),
                  title: const Text('Birleştir'),
                  subtitle: const Text('Mevcut verilerle birleştir (kopyalar atlanır)'),
                  dense: true,
                ),
                RadioListTile<RestoreMode>(
                  value: RestoreMode.replace,
                  groupValue: _selectedMode,
                  onChanged: (value) => setState(() => _selectedMode = value!),
                  title: const Text('Değiştir'),
                  subtitle: const Text('Tüm mevcut verileri sil ve yedekten geri yükle'),
                  dense: true,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isRestoring ? null : () => Navigator.pop(context),
          child: const Text('İPTAL'),
        ),
        FilledButton(
          onPressed: _isRestoring ? null : _performRestore,
          child: _isRestoring
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('GERİ YÜKLE'),
        ),
      ],
    );
  }
  Future<void> _performRestore() async {
    if (_controller.text.trim().isEmpty) {
      widget.notificationService.showWarning(
        'Lütfen yedek verisini girin.',
        title: 'Eksik Veri',
      );
      return;
    }

    setState(() => _isRestoring = true);
    widget.onRestoreStarted();

    try {
      widget.logger.info('Starting data restoration', tag: 'Settings', data: {
        'mode': _selectedMode.toString(),
      });

      // Parse JSON string to Map
      final Map<String, dynamic> backupData = jsonDecode(_controller.text.trim());
      
      final result = await BackupService.restoreFromBackup(
        backupData,
        mode: _selectedMode,
      );

      if (mounted) {
        Navigator.pop(context);
        
        final message = _selectedMode == RestoreMode.merge
            ? 'Geri yükleme tamamlandı!\n\n'
                'Eklenen: ${result.restoredCount}\n'
                'Atlanan: ${result.skippedCount}\n'
                'Hata: ${result.errorCount}'
            : 'Geri yükleme tamamlandı!\n\n'
                'Toplam: ${result.restoredCount}\n'
                'Hata: ${result.errorCount}';

        widget.notificationService.showSuccess(
          message,
          title: 'Geri Yükleme Başarılı',
        );
      }

      widget.logger.info('Data restoration completed successfully', tag: 'Settings', data: {
        'restoredCount': result.restoredCount,
        'skippedCount': result.skippedCount,
        'errorCount': result.errorCount,
      });
    } catch (e, stackTrace) {
      widget.logger.error('Failed to restore data', tag: 'Settings', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        Navigator.pop(context);
        widget.notificationService.showError(
          'Veri geri yüklenirken hata oluştu: $e',
          title: 'Geri Yükleme Hatası',
        );
      }
    } finally {
      widget.onRestoreCompleted();
    }
  }
}
