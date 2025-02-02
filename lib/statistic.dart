import 'package:flutter/material.dart';
import 'db_helper.dart';

class CarTrendsPage extends StatefulWidget {
  const CarTrendsPage({super.key});

  @override
  State<CarTrendsPage> createState() => _CarTrendsPageState();
}

class _CarTrendsPageState extends State<CarTrendsPage> {
  final dbHelper = DBHelper();
  Map<String, int> brandDistribution = {};
  Map<String, int> soldBrandDistribution = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    try {
      final cars = await dbHelper.getCars();

      // Marka dağılımını hesapla
      final Map<String, int> brandCounts = {};
      final Map<String, int> soldBrandCounts = {};

      for (var car in cars) {
        // Toplam marka dağılımı
        brandCounts[car.brand] = (brandCounts[car.brand] ?? 0) + 1;

        // Satılan araçların marka dağılımı
        if (car.isSold) {
          soldBrandCounts[car.brand] = (soldBrandCounts[car.brand] ?? 0) + 1;
        }
      }

      setState(() {
        brandDistribution = brandCounts;
        soldBrandDistribution = soldBrandCounts;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Trendler yüklenirken hata: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Otomobil Trendleri'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTrends,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTrendCard(
                    context,
                    'Marka Dağılımı',
                    _calculatePercentages(brandDistribution),
                  ),
                  const SizedBox(height: 16),
                  _buildTrendCard(
                    context,
                    'Satılan Araçların Marka Dağılımı',
                    _calculatePercentages(soldBrandDistribution),
                  ),
                ],
              ),
            ),
    );
  }

  List<Map<String, dynamic>> _calculatePercentages(
      Map<String, int> distribution) {
    if (distribution.isEmpty) {
      return [
        {'name': 'Veri yok', 'percentage': 100},
      ];
    }

    final total = distribution.values.reduce((a, b) => a + b);
    return distribution.entries.map((entry) {
      final percentage = (entry.value / total * 100).round();
      return {
        'name': entry.key,
        'percentage': percentage,
      };
    }).toList()
      ..sort(
          (a, b) => (b['percentage'] as int).compareTo(a['percentage'] as int));
  }

  Widget _buildTrendCard(
      BuildContext context, String title, List<Map<String, dynamic>> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              item['name'],
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          Expanded(
                            flex: 7,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item['percentage'] / 100,
                                minHeight: 8,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${item['percentage']}%',
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  final dbHelper = DBHelper();
  int totalCars = 0;
  int soldCars = 0;
  Map<String, int> soldBrandDistribution = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final cars = await dbHelper.getCars();

      // Toplam ve satılan araç sayısını hesapla
      totalCars = cars.length;
      soldCars = cars.where((car) => car.isSold).length;

      // Satılan araçların marka dağılımını hesapla
      final Map<String, int> soldBrandCounts = {};
      for (var car in cars) {
        if (car.isSold) {
          soldBrandCounts[car.brand] = (soldBrandCounts[car.brand] ?? 0) + 1;
        }
      }

      setState(() {
        soldBrandDistribution = soldBrandCounts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Araç İstatistikleri'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : totalCars == 0
              ? Center(
                  child: Text(
                    'Henüz araç eklenmedi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStatistics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatisticCard(
                        context,
                        'Toplam Araç Sayısı',
                        totalCars.toString(),
                      ),
                      const SizedBox(height: 16),
                      _buildStatisticCard(
                        context,
                        'Satılan Araç Sayısı',
                        soldCars.toString(),
                      ),
                      const SizedBox(height: 16),
                      _buildStatisticCard(
                        context,
                        'Satılan Araçların Marka Dağılımı',
                        _calculatePercentages(soldBrandDistribution),
                      ),
                    ],
                  ),
                ),
    );
  }

  List<Map<String, dynamic>> _calculatePercentages(
      Map<String, int> distribution) {
    if (distribution.isEmpty) {
      return [
        {'name': 'Veri yok', 'percentage': 100},
      ];
    }

    final total = distribution.values.reduce((a, b) => a + b);
    return distribution.entries.map((entry) {
      final percentage = (entry.value / total * 100).round();
      return {
        'name': entry.key,
        'percentage': percentage,
      };
    }).toList()
      ..sort(
          (a, b) => (b['percentage'] as int).compareTo(a['percentage'] as int));
  }

  Widget _buildStatisticCard(
      BuildContext context, String title, dynamic content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (content is String)
              Text(
                content,
                style: Theme.of(context).textTheme.headlineMedium,
              )
            else if (content is List<Map<String, dynamic>>)
              ...content.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item['name'],
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: item['percentage'] / 100,
                                  minHeight: 8,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                '${item['percentage']}%',
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
