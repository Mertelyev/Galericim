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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Satış Trendleri'),
        actions: [
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
            _buildMonthlySalesChart(),
            const SizedBox(height: 24),
            _buildTopBrandsChart(),
            const SizedBox(height: 24),
            _buildAveragePriceChart(),
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
              height: 220,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthlySales
                      .map((data) => _buildBarChart(data, maxCount))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> data, int maxCount) {
    final height = (data['count'] as int) / maxCount * 150;

    return Container(
      width: 60,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${data['count']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['month'],
            style: const TextStyle(fontSize: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(brand['brand']),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 16),
          Text('$percentage%'),
          const SizedBox(width: 8),
          Text('(${brand['count']})'),
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
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${averagePrice.toStringAsFixed(0)} TL',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                    Text(
                      'Ortalama Fiyat',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
}
