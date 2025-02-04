import 'package:flutter/material.dart';

class TrendsPage extends StatelessWidget {
  const TrendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Otomobil Trendleri'),
      ),
      body: Center(
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
              'Yakında Burada',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Otomobil satış trendleri burada görüntülenecek',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
