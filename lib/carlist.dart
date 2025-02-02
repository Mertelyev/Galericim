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
    try {
      if (car.id == null) {
        await dbHelper.insertCar(car);
      } else {
        await dbHelper.updateCar(car);
      }
      await _loadCars(); // Listeyi yenile
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Araç kaydedilirken hata oluştu: $e')),
        );
      }
    }
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
                  child: Row(
                    children: [
                      Text(
                        car.brand,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Text(' - '),
                      Text(
                        car.model,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w400,
                                ),
                      ),
                      if (car.package != null && car.package!.isNotEmpty) ...[
                        const Text(' - '),
                        Text(
                          car.package!,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ],
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
                const SizedBox(height: 12), // Boşluk artırıldı
                Text(
                  '${car.year} - ${car.price} TL',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8), // Yeni boşluk eklendi
                if (car.damageRecord != '0')
                  Text(
                    'Hasar Kaydı: ${car.damageRecord} TL',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 8), // Yeni boşluk eklendi
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
                // Açıklama ile üst kısım arasına ekstra boşluk
                if (car.description != null && car.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Açıklama:',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          car.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
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
    final formKey = GlobalKey<FormState>();
    String brand = '';
    String model = '';
    String package = ''; // Yeni eklenen paket bilgisi
    String year = '';
    String price = '';
    String damageRecord = '0';
    String description = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Araç Ekle'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Marka',
                    prefixIcon: Icon(Icons.branding_watermark),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Marka gereklidir';
                    }
                    return null;
                  },
                  onSaved: (value) => brand = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    prefixIcon: Icon(Icons.model_training),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Model gereklidir';
                    }
                    return null;
                  },
                  onSaved: (value) => model = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Paket (Opsiyonel)',
                    prefixIcon: Icon(Icons.style),
                    hintText: 'Örn: Premium, Elegance, Urban...',
                  ),
                  onSaved: (value) => package = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Yıl',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Yıl gereklidir';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Geçerli bir yıl giriniz';
                    }
                    return null;
                  },
                  onSaved: (value) => year = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Fiyat (TL)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Fiyat gereklidir';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Geçerli bir fiyat giriniz';
                    }
                    return null;
                  },
                  onSaved: (value) => price = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Hasar Kaydı (TL)',
                    prefixIcon: Icon(Icons.warning_amber),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: '0',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Hasar kaydı gereklidir';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Geçerli bir değer giriniz';
                    }
                    return null;
                  },
                  onSaved: (value) => damageRecord = value ?? '0',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  onSaved: (value) => description = value ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                final newCar = Car(
                  brand: brand,
                  model: model,
                  package: package.isNotEmpty ? package : null,
                  year: year,
                  price: price,
                  addedDate: DateTime.now(),
                  damageRecord: damageRecord,
                  description: description.isNotEmpty ? description : null,
                );

                _saveCar(newCar);
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
