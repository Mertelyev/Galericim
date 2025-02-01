import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlaması için eklendi
import 'db_helper.dart';
import 'car.dart';

class CarListPage extends StatefulWidget {
  const CarListPage({super.key});

  @override
  State<CarListPage> createState() => _CarListPageState();
}

class _CarListPageState extends State<CarListPage> {
  final List<Car> cars = [];
  final dateFormat = DateFormat('dd.MM.yyyy');
  final dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    try {
      final loadedCars = await dbHelper.getCars();
      setState(() {
        cars.clear(); // Önceki araçları temizle
        cars.addAll(loadedCars);
      });
    } catch (e) {
      debugPrint('Araçlar yüklenirken hata: $e');
      // Kullanıcıya hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Araçlar yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _saveCar(Car car) async {
    if (car.id == null) {
      await dbHelper.insertCar(car);
    } else {
      await dbHelper.updateCar(car);
    }
    _loadCars();
  }

  Future<void> _deleteCar(int id) async {
    await dbHelper.deleteCar(id);
    _loadCars();
  }

  List<Car> _getSortedCars() {
    return [...cars]..sort((a, b) {
        if (a.isSold != b.isSold) {
          return a.isSold ? 1 : -1;
        }
        return b.addedDate.compareTo(a.addedDate);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Araç Stok Listesi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: cars.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz araç eklenmemiş',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _getSortedCars().length,
                itemBuilder: (context, index) {
                  final car = _getSortedCars()[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildCarTile(car),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCarDialog(),
        label: const Text('Araç Ekle'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCarTile(Car car) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: car.isSold
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.directions_car,
                color: car.isSold
                    ? Theme.of(context).colorScheme.onSecondary
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '${car.brand} ${car.model}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (car.isSold)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SATILDI',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  '${car.year} - ${car.price} TL',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Eklenme: ${dateFormat.format(car.addedDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (car.isSold && car.soldDate != null)
                  Text(
                    'Satış: ${dateFormat.format(car.soldDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: car.isSold
                      ? const Icon(Icons.undo)
                      : const Icon(Icons.check_circle_outline),
                  tooltip: car.isSold
                      ? 'Satış durumunu geri al'
                      : 'Satıldı olarak işaretle',
                  onPressed: () => _showToggleSoldDialog(car),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() {
                      _deleteCar(car.id!);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showToggleSoldDialog(Car car) {
    final action = car.isSold ? 'geri al' : 'satıldı olarak işaretle';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Satış Durumu Değişikliği'),
        content: Text('Bu aracın satış durumunu $action?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                if (car.isSold) {
                  car.markAsUnsold();
                } else {
                  car.markAsSold();
                }
                _saveCar(car);
              });
              Navigator.pop(context);
            },
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _showAddCarDialog() {
    String brand = '';
    String model = '';
    String year = '';
    String price = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Araç Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Marka',
                  prefixIcon: Icon(Icons.branding_watermark),
                ),
                onChanged: (value) => brand = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Model',
                  prefixIcon: Icon(Icons.model_training),
                ),
                onChanged: (value) => model = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Yıl',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => year = value,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Fiyat',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => price = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          FilledButton(
            onPressed: () {
              if (brand.isNotEmpty &&
                  model.isNotEmpty &&
                  year.isNotEmpty &&
                  price.isNotEmpty) {
                if (int.tryParse(year) == null ||
                    double.tryParse(price) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Yıl ve fiyat sayısal değerler olmalıdır.'),
                    ),
                  );
                  return;
                }

                final newCar = Car(
                  brand: brand,
                  model: model,
                  year: year,
                  price: price,
                  addedDate: DateTime.now(),
                );

                setState(() {
                  cars.add(newCar);
                  _saveCar(newCar);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('EKLE'),
          ),
        ],
      ),
    );
  }
}
