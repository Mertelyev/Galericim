import 'package:flutter/material.dart';
import 'db_helper.dart';

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
  Map<String, int> fuelTypeDistribution = {}; // Yeni eklendi
  double averagePrice = 0; // Yeni eklendi
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final cars = await dbHelper.getCars();
      final soldCarsOnly = cars.where((car) => car.isSold).toList();

      setState(() {
        totalCars = cars.length;
        soldCars = cars.where((car) => car.isSold).length;

        // Satılan araçların marka dağılımını hesapla
        for (var car in cars) {
          if (car.isSold) {
            soldBrandDistribution[car.brand] =
                (soldBrandDistribution[car.brand] ?? 0) + 1;
          }
        }

        // Yakıt tipi dağılımı hesapla
        fuelTypeDistribution.clear();
        for (var car in soldCarsOnly) {
          if (car.fuelType != null) {
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
        }

        isLoading = false;
      });
    } catch (e) {
      debugPrint('İstatistikler yüklenirken hata: $e');
      setState(() {
        isLoading = false;
      });
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
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dynamicColor = brightness == Brightness.dark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        elevation: 0,
        scrolledUnderElevation: 3,
        actions: [
          IconButton.outlined(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İstatistik kartları - Tek satırda
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              // Toplam Araç
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      size: 24,
                                      color: dynamicColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      totalCars.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      'Toplam',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              VerticalDivider(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              // Stokta
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inventory_2,
                                      size: 24,
                                      color: dynamicColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      (totalCars - soldCars).toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      'Stokta',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    if (totalCars > 0)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: dynamicColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '%${(((totalCars - soldCars) / totalCars) * 100).round()}',
                                          style: TextStyle(
                                            color: dynamicColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              VerticalDivider(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              // Satılan
                              Expanded(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.sell,
                                      size: 24,
                                      color: dynamicColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      soldCars.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      'Satılan',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    if (totalCars > 0)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: dynamicColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '%${((soldCars / totalCars) * 100).round()}',
                                          style: TextStyle(
                                            color: dynamicColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Marka Dağılımı
                    if (soldBrandDistribution.isNotEmpty) ...[
                      const SizedBox(height: 24),
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

                    const SizedBox(height: 24),
                    _buildDetailCard(
                      title: 'Satış İstatistikleri',
                      icon: Icons.analytics,
                      children: [
                        _buildInfoRow(
                          'Ortalama Satış Fiyatı',
                          '${averagePrice.toStringAsFixed(0)} TL',
                        ),
                        // Daha fazla istatistik eklenebilir
                      ],
                    ),
                  ],
                ),
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
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: dynamicColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(dynamicColor),
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
