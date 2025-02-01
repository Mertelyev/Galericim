import 'package:flutter/material.dart';

class CarTrendsPage extends StatelessWidget {
  const CarTrendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Otomobil Trendleri'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTrendCard(
            context,
            'En Çok Satan Markalar',
            [
              {'name': 'Toyota', 'percentage': 25},
              {'name': 'Volkswagen', 'percentage': 20},
              {'name': 'Ford', 'percentage': 15},
            ],
          ),
          const SizedBox(height: 16),
          _buildTrendCard(
            context,
            'Popüler Segment',
            [
              {'name': 'SUV', 'percentage': 40},
              {'name': 'Sedan', 'percentage': 35},
              {'name': 'Hatchback', 'percentage': 25},
            ],
          ),
          const SizedBox(height: 16),
          _buildTrendCard(
            context,
            'Yakıt Tercihi',
            [
              {'name': 'Benzin', 'percentage': 45},
              {'name': 'Dizel', 'percentage': 35},
              {'name': 'Hibrit', 'percentage': 20},
            ],
          ),
        ],
      ),
    );
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
            ...items
                .map((item) => Padding(
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
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }
}
