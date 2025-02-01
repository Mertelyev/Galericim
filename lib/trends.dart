import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'car.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  final dbHelper = DBHelper();
  List<Car> cars = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    try {
      final loadedCars = await dbHelper.getCars();
      setState(() {
        cars = loadedCars;
        isLoading = false;
      });
    } catch (e) {
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
              onRefresh: _loadCars,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cars.length,
                itemBuilder: (context, index) {
                  final car = cars[index];
                  return Card(
                    child: ListTile(
                      title: Text('${car.brand} ${car.model}'),
                      subtitle:
                          Text('Yıl: ${car.year}, Fiyat: ${car.price} TL'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
