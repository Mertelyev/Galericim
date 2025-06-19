import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'car.dart';
import 'services/logging_service.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  final dbHelper = DBHelper();
  final logger = LoggingService();
  List<Car> cars = [];
  int totalCars = 0;
  int soldCars = 0;
  Map<String, int> soldBrandDistribution = {};
  Map<String, int> fuelTypeDistribution = {};
  double averagePrice = 0;
  bool isLoading = true;
  String? errorMessage;
  String selectedPeriod = 'Tümü';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      logger.info('Loading statistics from database', tag: 'Statistics');
      final loadedCars = await dbHelper.getCars();
      setState(() {
        cars = loadedCars;
        totalCars = loadedCars.length;
        soldCars = loadedCars.where((car) => car.isSold).length;

        // Satılan araçların marka dağılımını hesapla
        soldBrandDistribution.clear();
        for (var car in loadedCars) {
          if (car.isSold) {
            soldBrandDistribution[car.brand] =
                (soldBrandDistribution[car.brand] ?? 0) + 1;
          }
        }

        // Yakıt tipi dağılımı hesapla
        fuelTypeDistribution.clear();
        final soldCarsOnly = loadedCars.where((car) => car.isSold).toList();
        for (var car in soldCarsOnly) {
          if (car.fuelType != null && car.fuelType!.isNotEmpty) {
            fuelTypeDistribution[car.fuelType!] =
                (fuelTypeDistribution[car.fuelType!] ?? 0) + 1;
          }
        }

        // Ortalama satış fiyatı hesapla
        if (soldCarsOnly.isNotEmpty) {
          final totalPrice = soldCarsOnly.fold<double>(
            0,
            (sum, car) =>
                sum + (double.tryParse(car.price.replaceAll(',', '')) ?? 0),
          );
          averagePrice = totalPrice / soldCarsOnly.length;
        } else {
          averagePrice = 0;
        }

        isLoading = false;
      });

      logger.info('Successfully loaded statistics', tag: 'Statistics', data: {
        'totalCars': totalCars,
        'soldCars': soldCars,
        'brandCount': soldBrandDistribution.length,
        'fuelTypeCount': fuelTypeDistribution.length,
        'averagePrice': averagePrice.toStringAsFixed(0),
      });
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load statistics',
        tag: 'Statistics',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        isLoading = false;
        errorMessage = 'İstatistikler yüklenirken hata oluştu: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('İstatistikler yüklenirken hata oluştu'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Tekrar Dene',
              onPressed: _loadStatistics,
            ),
          ),
        );
      }
    }
  }

  List<Car> _getFilteredCars() {
    final now = DateTime.now();
    switch (selectedPeriod) {
      case 'Bu Yıl':
        return cars
            .where((car) =>
                car.isSold &&
                car.soldDate != null &&
                car.soldDate!.year == now.year)
            .toList();
      case 'Bu Ay':
        return cars
            .where((car) =>
                car.isSold &&
                car.soldDate != null &&
                car.soldDate!.year == now.year &&
                car.soldDate!.month == now.month)
            .toList();
      case 'Son 3 Ay':
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return cars
            .where((car) =>
                car.isSold &&
                car.soldDate != null &&
                car.soldDate!.isAfter(threeMonthsAgo))
            .toList();
      case 'Son 6 Ay':
        final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);
        return cars
            .where((car) =>
                car.isSold &&
                car.soldDate != null &&
                car.soldDate!.isAfter(sixMonthsAgo))
            .toList();
      default:
        return cars.where((car) => car.isSold).toList();
    }
  }

  List<Map<String, dynamic>> _calculatePercentages(
      Map<String, int> distribution) {
    if (distribution.isEmpty) {
      return [
        {'name': 'Veri yok', 'percentage': 100, 'count': 0},
      ];
    }

    final total = distribution.values.reduce((a, b) => a + b);
    return distribution.entries.map((entry) {
      final percentage = (entry.value / total * 100).round();
      return {
        'name': entry.key,
        'percentage': percentage,
        'count': entry.value,
      };
    }).toList()
      ..sort(
          (a, b) => (b['percentage'] as int).compareTo(a['percentage'] as int));
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final filteredCars = _getFilteredCars();
    final totalRevenue = _getTotalRevenue(filteredCars);
    final avgDaysToSell = _getAverageDaysToSell(filteredCars);
    final conversionRate =
        cars.isNotEmpty ? (filteredCars.length / cars.length * 100) : 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildMetricCard(
          'Toplam Araç',
          totalCars.toString(),
          Icons.directions_car,
          Colors.blue,
        ),
        _buildMetricCard(
          'Satılan Araç',
          '${filteredCars.length}',
          Icons.sell,
          Colors.green,
        ),
        _buildMetricCard(
          'Stokta Araç',
          '${totalCars - soldCars}',
          Icons.inventory_2,
          Colors.orange,
        ),
        _buildMetricCard(
          'Toplam Ciro',
          totalRevenue >= 1000000
              ? '${(totalRevenue / 1000000).toStringAsFixed(1)}M TL'
              : '${(totalRevenue / 1000).toStringAsFixed(0)}K TL',
          Icons.attach_money,
          Colors.purple,
        ),
        _buildMetricCard(
          'Ort. Satış Süresi',
          avgDaysToSell > 0
              ? avgDaysToSell >= 30
                  ? '${(avgDaysToSell / 30).toStringAsFixed(1)} ay'
                  : '${avgDaysToSell.toStringAsFixed(0)} gün'
              : 'Henüz veri yok',
          Icons.timer,
          Colors.red,
        ),
        _buildMetricCard(
          'Satış Oranı',
          '${conversionRate.toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySalesChart() {
    final monthlyData = _getMonthlySalesData();

    if (monthlyData.isEmpty) {
      return _buildDetailCard(
        title: 'Aylık Satışlar',
        icon: Icons.bar_chart,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.insert_chart_outlined,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz satış verisi yok',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Araç satışları gerçekleştikçe burada görüntülenecek',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final maxCount = monthlyData.fold<int>(
        0,
        (max, data) =>
            (data['count'] as int) > max ? data['count'] as int : max);

    return _buildDetailCard(
      title: 'Aylık Satışlar',
      icon: Icons.bar_chart,
      children: [
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: monthlyData.map((data) {
                final count = data['count'] as int;
                final height = maxCount > 0 ? (count / maxCount * 150) : 0.0;

                return GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${data['month']}: $count satış'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          count.toString(),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 30,
                          height: height,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['month'] as String,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRangeChart() {
    final priceRanges = _getPriceRangeData();

    if (priceRanges.isEmpty) {
      return _buildDetailCard(
        title: 'Fiyat Aralığı Analizi',
        icon: Icons.analytics,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz satış verisi yok',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seçili dönemde satış yapıldıkça fiyat analizi burada görüntülenecek',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return _buildDetailCard(
      title: 'Fiyat Aralığı Analizi',
      icon: Icons.analytics,
      children:
          priceRanges.map((range) => _buildPriceRangeItem(range)).toList(),
    );
  }

  Widget _buildPriceRangeItem(Map<String, dynamic> range) {
    final totalSold = _getFilteredCars().length;
    final percentage =
        totalSold > 0 ? (range['count'] / totalSold * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              range['range'],
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: percentage / 100),
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.grey[300],
                    color: _getPriceRangeColor(range['range']),
                    minHeight: 8,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              '$percentage%',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 28,
            child: Text(
              '(${range['count']})',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriceRangeColor(String range) {
    switch (range) {
      case '0-100K':
        return Colors.green;
      case '100K-300K':
        return Colors.blue;
      case '300K-500K':
        return Colors.orange;
      case '500K-1M':
        return Colors.red;
      case '1M+':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPerformanceMetrics() {
    final highestPrice = _getHighestPrice();
    final lowestPrice = _getLowestPrice();
    final avgPrice = _getAveragePrice();

    return _buildDetailCard(
      title: 'Performans Metrikleri',
      icon: Icons.speed,
      children: [
        _buildPerformanceItem(
          'En Yüksek Satış',
          highestPrice > 0
              ? '${highestPrice.toStringAsFixed(0)} TL'
              : 'Henüz satış yok',
          Icons.arrow_upward,
          Colors.red,
        ),
        const SizedBox(height: 8),
        _buildPerformanceItem(
          'En Düşük Satış',
          lowestPrice > 0
              ? '${lowestPrice.toStringAsFixed(0)} TL'
              : 'Henüz satış yok',
          Icons.arrow_downward,
          Colors.orange,
        ),
        const SizedBox(height: 8),
        _buildPerformanceItem(
          'Ortalama Fiyat',
          avgPrice > 0
              ? '${avgPrice.toStringAsFixed(0)} TL'
              : 'Henüz satış yok',
          Icons.analytics,
          Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildPerformanceItem(
          'Toplam Marka',
          '${cars.map((car) => car.brand).toSet().length}',
          Icons.branding_watermark,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildPerformanceItem(
      String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        elevation: 0,
        scrolledUnderElevation: 3,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Zaman Dilimi',
            onSelected: (value) {
              setState(() {
                selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Tümü', child: Text('Tüm Zamanlar')),
              const PopupMenuItem(value: 'Bu Yıl', child: Text('Bu Yıl')),
              const PopupMenuItem(value: 'Bu Ay', child: Text('Bu Ay')),
              const PopupMenuItem(value: 'Son 3 Ay', child: Text('Son 3 Ay')),
              const PopupMenuItem(value: 'Son 6 Ay', child: Text('Son 6 Ay')),
            ],
          ),
          IconButton.outlined(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'İstatistikler yükleniyor...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Veriler analiz ediliyor',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Hata Oluştu',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadStatistics,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }
    if (totalCars == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bar_chart_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Henüz Veri Yok',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'İstatistik görmek için araç ekleyin',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Araçlar eklendikçe detaylı analizler burada görüntülenecek',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zaman dilimi gösterici
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Seçili Dönem: $selectedPeriod',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Genel İstatistik Kartları (Gelişmiş)
            Text(
              'Genel İstatistikler',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildOverviewCards(),
            const SizedBox(height: 24),

            // Aylık Satış Grafiği
            _buildMonthlySalesChart(),
            const SizedBox(height: 24),

            // Marka Dağılımı (Mevcut tasarımı koruyarak)
            if (soldBrandDistribution.isNotEmpty) ...[
              Text(
                'Satış Dağılımı',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildDetailCard(
                title: 'Markalar',
                icon: Icons.pie_chart,
                children: _calculatePercentages(soldBrandDistribution)
                    .map((item) => _buildDistributionRow(
                          item['name'] as String,
                          item['percentage'] as int,
                          item['count'] as int,
                        ))
                    .toList(),
              ),
            ],

            // Yakıt Tipi Dağılımı
            if (fuelTypeDistribution.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildDetailCard(
                title: 'Yakıt Tipi Dağılımı',
                icon: Icons.local_gas_station,
                children: _calculatePercentages(fuelTypeDistribution)
                    .map((item) => _buildDistributionRow(
                          item['name'] as String,
                          item['percentage'] as int,
                          item['count'] as int,
                        ))
                    .toList(),
              ),
            ],

            // Fiyat Aralığı Analizi
            const SizedBox(height: 24),
            _buildPriceRangeChart(),

            // Performans Metrikleri
            const SizedBox(height: 24),
            _buildPerformanceMetrics(),

            // Satış İstatistikleri (Mevcut)
            const SizedBox(height: 24),
            _buildDetailCard(
              title: 'Detaylı İstatistikler',
              icon: Icons.analytics,
              children: [
                _buildInfoRow(
                  'Ortalama Satış Fiyatı',
                  '${averagePrice.toStringAsFixed(0)} TL',
                ),
                _buildInfoRow(
                  'Toplam Model Yılı',
                  '${cars.map((car) => car.year).toSet().length}',
                ),
                _buildInfoRow(
                  'Stok Oranı',
                  '${totalCars > 0 ? (((totalCars - soldCars) / totalCars) * 100).toStringAsFixed(1) : 0}%',
                ),
                _buildInfoRow(
                  'Satış Oranı',
                  '${totalCars > 0 ? ((soldCars / totalCars) * 100).toStringAsFixed(1) : 0}%',
                ),
                if (cars.isNotEmpty) ...[
                  _buildInfoRow(
                    'En Eski Araç',
                    _getOldestCarYear(),
                  ),
                  _buildInfoRow(
                    'En Yeni Araç',
                    _getNewestCarYear(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionRow(String name, int percentage, int count) {
    final brightness = Theme.of(context).brightness;
    final dynamicColor = brightness == Brightness.dark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Text(
                '$count araç',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: dynamicColor,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: dynamicColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '%$percentage',
                  style: TextStyle(
                    color: dynamicColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: percentage / 100),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: dynamicColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(dynamicColor),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // Yardımcı metodlar
  List<Map<String, dynamic>> _getMonthlySalesData() {
    final soldCars =
        cars.where((car) => car.isSold && car.soldDate != null).toList();
    final monthNames = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];

    final monthCounts = <int, int>{};

    for (final car in soldCars) {
      final month = car.soldDate!.month;
      monthCounts[month] = (monthCounts[month] ?? 0) + 1;
    }

    return List.generate(12, (index) {
      final month = index + 1;
      return {
        'month': monthNames[index],
        'count': monthCounts[month] ?? 0,
      };
    }).where((data) => (data['count'] as int) > 0).toList();
  }

  double _getTotalRevenue(List<Car> soldCars) {
    double total = 0;
    for (final car in soldCars) {
      final price = double.tryParse(car.price.replaceAll(',', ''));
      if (price != null) {
        total += price;
      }
    }
    return total;
  }

  double _getAverageDaysToSell(List<Car> soldCars) {
    if (soldCars.isEmpty) return 0;

    int totalDays = 0;
    int count = 0;

    for (final car in soldCars) {
      if (car.soldDate != null) {
        final daysToSell = car.soldDate!.difference(car.addedDate).inDays;
        if (daysToSell >= 0) {
          totalDays += daysToSell;
          count++;
        }
      }
    }

    return count > 0 ? totalDays / count : 0;
  }

  double _getHighestPrice() {
    final soldCars = _getFilteredCars();
    if (soldCars.isEmpty) return 0;

    double highest = 0;
    for (final car in soldCars) {
      final price = double.tryParse(car.price.replaceAll(',', ''));
      if (price != null && price > highest) {
        highest = price;
      }
    }
    return highest;
  }

  double _getLowestPrice() {
    final soldCars = _getFilteredCars();
    if (soldCars.isEmpty) return 0;

    double lowest = double.infinity;
    for (final car in soldCars) {
      final price = double.tryParse(car.price.replaceAll(',', ''));
      if (price != null && price < lowest) {
        lowest = price;
      }
    }
    return lowest == double.infinity ? 0 : lowest;
  }

  double _getAveragePrice() {
    final soldCars = _getFilteredCars();
    if (soldCars.isEmpty) return 0;

    double total = 0;
    int count = 0;

    for (final car in soldCars) {
      final price = double.tryParse(car.price.replaceAll(',', ''));
      if (price != null) {
        total += price;
        count++;
      }
    }

    return count > 0 ? total / count : 0;
  }

  List<Map<String, dynamic>> _getPriceRangeData() {
    final soldCars = _getFilteredCars();
    final ranges = {
      '0-100K': 0,
      '100K-300K': 0,
      '300K-500K': 0,
      '500K-1M': 0,
      '1M+': 0,
    };

    for (final car in soldCars) {
      final price = double.tryParse(car.price.replaceAll(',', ''));
      if (price != null) {
        if (price < 100000) {
          ranges['0-100K'] = ranges['0-100K']! + 1;
        } else if (price < 300000) {
          ranges['100K-300K'] = ranges['100K-300K']! + 1;
        } else if (price < 500000) {
          ranges['300K-500K'] = ranges['300K-500K']! + 1;
        } else if (price < 1000000) {
          ranges['500K-1M'] = ranges['500K-1M']! + 1;
        } else {
          ranges['1M+'] = ranges['1M+']! + 1;
        }
      }
    }

    return ranges.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {
              'range': entry.key,
              'count': entry.value,
            })
        .toList();
  }

  String _getOldestCarYear() {
    if (cars.isEmpty) return 'N/A';

    final years = cars
        .map((car) => int.tryParse(car.year) ?? 0)
        .where((year) => year > 0)
        .toList();

    if (years.isEmpty) return 'N/A';

    final oldestYear = years.reduce((a, b) => a < b ? a : b);
    return oldestYear.toString();
  }

  String _getNewestCarYear() {
    if (cars.isEmpty) return 'N/A';

    final years = cars
        .map((car) => int.tryParse(car.year) ?? 0)
        .where((year) => year > 0)
        .toList();

    if (years.isEmpty) return 'N/A';

    final newestYear = years.reduce((a, b) => a > b ? a : b);
    return newestYear.toString();
  }
}
