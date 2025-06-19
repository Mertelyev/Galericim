import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'car.dart';
import 'services/logging_service.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  final dbHelper = DBHelper();
  final logger = LoggingService();
  List<Car> cars = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedPeriod = 'Tümü';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      logger.info('Loading trends data from database', tag: 'Trends');
      final loadedCars = await dbHelper.getCars();
      setState(() {
        cars = loadedCars;
        isLoading = false;
      });

      logger.info('Successfully loaded trends data', tag: 'Trends', data: {
        'totalCars': loadedCars.length,
        'soldCars': loadedCars.where((car) => car.isSold).length,
      });
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load trends data',
        tag: 'Trends',
        error: e,
        stackTrace: stackTrace,
      );

      setState(() {
        isLoading = false;
        errorMessage =
            'Trend verileri yüklenirken hata oluştu: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trend verileri yüklenirken hata oluştu'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Tekrar Dene',
              onPressed: _loadData,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Satış Trendleri'),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Trend verileri yükleniyor...'),
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
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (cars.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            _buildOverviewCards(),
            const SizedBox(height: 24),
            _buildMonthlySalesChart(),
            const SizedBox(height: 24),
            _buildTopBrandsChart(),
            const SizedBox(height: 24),
            _buildAveragePriceChart(),
            const SizedBox(height: 24),
            _buildPriceRangeChart(),
            const SizedBox(height: 24),
            _buildInventoryMetrics(),
            const SizedBox(height: 24),
            _buildPerformanceMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 100,
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz Veri Yok',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Trend analizi için araç satışları gerekli',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zaman Dönemi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ['Tümü', 'Bu Yıl', 'Bu Ay', 'Son 3 Ay', 'Son 6 Ay']
                  .map((period) => FilterChip(
                        label: Text(
                          period == 'Tümü' ? 'Tüm Zamanlar' : period,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: selectedPeriod == period,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              selectedPeriod = period;
                            });
                          }
                        },
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final filteredCars = _getFilteredCars();
    final totalCars = cars.length;
    final soldCars = filteredCars.length;
    final availableCars = cars.where((car) => !car.isSold).length;
    final totalRevenue = _getTotalRevenue(filteredCars);
    final avgDaysToSell = _getAverageDaysToSell(filteredCars);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildOverviewCard(
          'Toplam Araç',
          totalCars.toString(),
          Icons.directions_car,
          Colors.blue,
        ),
        _buildOverviewCard(
          'Satılan Araç',
          soldCars.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildOverviewCard(
          'Stokta Araç',
          availableCars.toString(),
          Icons.inventory,
          Colors.orange,
        ),
        _buildOverviewCard(
          'Toplam Ciro',
          '${totalRevenue.toStringAsFixed(0)} TL',
          Icons.attach_money,
          Colors.purple,
        ),
        _buildOverviewCard(
          'Ort. Satış Süresi',
          '${avgDaysToSell.toStringAsFixed(0)} gün',
          Icons.schedule,
          Colors.teal,
        ),
        _buildOverviewCard(
          'Satış Oranı',
          '${totalCars > 0 ? (soldCars / totalCars * 100).toStringAsFixed(1) : '0'}%',
          Icons.trending_up,
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
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
      ),
    );
  }

  Widget _buildMonthlySalesChart() {
    final monthlySales = _getMonthlySalesData();

    if (monthlySales.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aylık Satışlar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Henüz satış verisi yok'),
              ),
            ],
          ),
        ),
      );
    }

    final maxCount = monthlySales
        .map((e) => e['count'] as int)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aylık Satışlar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 64,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: monthlySales
                        .map((data) => _buildBarChart(data, maxCount))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> data, int maxCount) {
    final height = maxCount > 0 ? (data['count'] as int) / maxCount * 150 : 0.0;

    return Container(
      width: 55,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${data['count']}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 6),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data['month'],
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBrandsChart() {
    final brandData = _getBrandSalesData();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En Çok Satan Markalar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...brandData.take(5).map((brand) => _buildBrandItem(brand)),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandItem(Map<String, dynamic> brand) {
    final totalSold = cars.where((car) => car.isSold).length;
    final percentage =
        totalSold > 0 ? (brand['count'] / totalSold * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              brand['brand'],
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
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
              '(${brand['count']})',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAveragePriceChart() {
    final averagePrice = _getAveragePrice();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ortalama Satış Fiyatı',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${averagePrice.toStringAsFixed(0)} TL',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ortalama Fiyat',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeChart() {
    final priceRanges = _getPriceRangeData();

    if (priceRanges.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fiyat Aralığı Analizi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('Henüz satış verisi yok')),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fiyat Aralığı Analizi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...priceRanges.map((range) => _buildPriceRangeItem(range)),
          ],
        ),
      ),
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
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              color: _getPriceRangeColor(range['range']),
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

  Widget _buildInventoryMetrics() {
    final totalCars = cars.length;
    final soldCars = cars.where((car) => car.isSold).length;
    final availableCars = totalCars - soldCars;
    final brands = cars.map((car) => car.brand).toSet().length;
    final years = cars.map((car) => car.year).toSet().length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envanter Analizi',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Toplam Stok',
                    totalCars.toString(),
                    Icons.inventory_2,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricItem(
                    'Mevcut Stok',
                    availableCars.toString(),
                    Icons.store,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Marka Sayısı',
                    brands.toString(),
                    Icons.branding_watermark,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricItem(
                    'Model Yılı',
                    years.toString(),
                    Icons.calendar_today,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final filteredCars = _getFilteredCars();
    final conversionRate =
        cars.length > 0 ? (filteredCars.length / cars.length * 100) : 0;
    final highestPrice = _getHighestPrice();
    final lowestPrice = _getLowestPrice();
    final avgPrice = _getAveragePrice();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performans Metrikleri',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildPerformanceItem(
              'Dönüşüm Oranı',
              '${conversionRate.toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildPerformanceItem(
              'En Yüksek Satış',
              '${highestPrice.toStringAsFixed(0)} TL',
              Icons.arrow_upward,
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildPerformanceItem(
              'En Düşük Satış',
              '${lowestPrice.toStringAsFixed(0)} TL',
              Icons.arrow_downward,
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildPerformanceItem(
              'Ortalama Fiyat',
              '${avgPrice.toStringAsFixed(0)} TL',
              Icons.analytics,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
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

  List<Map<String, dynamic>> monthlySales = [];

  List<Map<String, dynamic>> _getMonthlySalesData() {
    if (monthlySales.isNotEmpty) return monthlySales;

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

    monthlySales = List.generate(12, (index) {
      final month = index + 1;
      return {
        'month': monthNames[index],
        'count': monthCounts[month] ?? 0,
      };
    }).where((data) => (data['count'] as int) > 0).toList();

    return monthlySales;
  }

  List<Map<String, dynamic>> _getBrandSalesData() {
    final soldCars = cars.where((car) => car.isSold).toList();
    final brandCounts = <String, int>{};

    for (final car in soldCars) {
      brandCounts[car.brand] = (brandCounts[car.brand] ?? 0) + 1;
    }

    final sortedBrands = brandCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedBrands
        .map((entry) => {
              'brand': entry.key,
              'count': entry.value,
            })
        .toList();
  }

  double _getAveragePrice() {
    final soldCars = cars.where((car) => car.isSold).toList();
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
}
