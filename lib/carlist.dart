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
  List<Car> filteredCars = [];
  bool isLoading = true;
  bool isSearching = false;
  final searchController = TextEditingController();

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
        filteredCars = loadedCars;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Araçlar yüklenirken hata: $e');
      // Kullanıcıya hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Araçlar yüklenirken hata oluştu: $e')),
        );
      }
      setState(() {
        isLoading = false;
      });
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
    // Filtrelenmiş listeyi kullan
    return [...filteredCars]..sort((a, b) {
        if (a.isSold != b.isSold) {
          return a.isSold ? 1 : -1;
        }
        return b.addedDate.compareTo(a.addedDate);
      });
  }

  void _filterCars(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredCars = cars;
      } else {
        final searchLower = query.toLowerCase().trim();

        filteredCars = cars.where((car) {
          final brandMatch = car.brand.toLowerCase().contains(searchLower);
          final modelMatch = car.model.toLowerCase().contains(searchLower);
          final packageMatch =
              car.package?.toLowerCase().contains(searchLower) ?? false;

          return brandMatch || modelMatch || packageMatch;
        }).toList();

        // Sonuçları alaka düzeyine göre sırala
        filteredCars.sort((a, b) {
          int scoreA = _getSearchScore(a, searchLower);
          int scoreB = _getSearchScore(b, searchLower);
          return scoreB.compareTo(scoreA);
        });
      }
    });
  }

  int _getSearchScore(Car car, String query) {
    int score = 0;

    // Tam eşleşmeler
    if (car.brand.toLowerCase() == query) score += 100;
    if (car.model.toLowerCase() == query) score += 100;
    if (car.package?.toLowerCase() == query) score += 100;

    // Başlangıç eşleşmeleri
    if (car.brand.toLowerCase().startsWith(query)) score += 50;
    if (car.model.toLowerCase().startsWith(query)) score += 50;
    if (car.package?.toLowerCase().startsWith(query) ?? false) score += 50;

    // İçerik eşleşmeleri
    if (car.brand.toLowerCase().contains(query)) score += 25;
    if (car.model.toLowerCase().contains(query)) score += 25;
    if (car.package?.toLowerCase().contains(query) ?? false) score += 25;

    return score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: !isSearching
            ? const Text('Araç Stok Listesi')
            : TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Marka, model veya paket ara...',
                  border: InputBorder.none,
                  hintStyle: Theme.of(context).brightness == Brightness.dark
                      ? TextStyle(color: Colors.white.withOpacity(0.7))
                      : TextStyle(color: Colors.black.withOpacity(0.7)),
                ),
                style: Theme.of(context).brightness == Brightness.dark
                    ? const TextStyle(color: Colors.white)
                    : const TextStyle(color: Colors.black),
                onChanged: _filterCars,
              ),
        actions: [
          if (isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isSearching = false;
                  searchController.clear();
                  filteredCars = cars;
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: filteredCars.isEmpty
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
      // Replace existing FAB(s) with a Stack of two Positioned FABs
      floatingActionButton: Stack(
        children: [
          // Search FAB - bottom left; position adjusted for better spacing
          Positioned(
            bottom: 2, // Azaltılmış alt boşluk
            left: 24, // Artırılmış sol boşluk
            child: FloatingActionButton(
              heroTag: 'searchFAB',
              onPressed: () {
                setState(() {
                  isSearching = true;
                });
              },
              child: const Icon(Icons.search),
            ),
          ),
          // "Araç Ekle" FAB - bottom right; position adjusted accordingly
          Positioned(
            bottom: 2,
            right: 0,
            child: FloatingActionButton.extended(
              heroTag: 'addFAB',
              onPressed: () => _showAddCarDialog(),
              label: const Text('Araç Ekle'),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarTile(Car car) {
    return Card(
      child: InkWell(
        // Add this
        onTap: () => _showCarDetails(car), // Add this
        child: Stack(
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
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Added for top alignment
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 4, // Horizontal spacing between items
                      children: [
                        Text(
                          car.brand,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const Text('-'),
                        Text(
                          car.model,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w400,
                                  ),
                        ),
                        if (car.package != null && car.package!.isNotEmpty) ...[
                          const Text('-'),
                          Text(
                            car.package!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ],
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
                  if (car.description != null &&
                      car.description!.isNotEmpty) ...[
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
                  Flexible(
                    child: IconButton(
                      icon: car.isSold
                          ? const Icon(Icons.undo)
                          : const Icon(Icons.check_circle_outline),
                      tooltip: car.isSold
                          ? 'Satış durumunu geri al'
                          : 'Satıldı olarak işaretle',
                      onPressed: () => _showToggleSoldDialog(car),
                    ),
                  ),
                  Flexible(
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          _deleteCar(car.id!);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (car.isSold)
              Positioned(
                top: 18,
                right: 18,
                child: Container(
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
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showToggleSoldDialog(Car car) {
    final formKey = GlobalKey<FormState>();
    String? customerName;
    String? customerCity;
    String? customerPhone;
    String? customerTcNo;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Satış Durumu Değişikliği'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bu aracı satıldı olarak işaretlemek istiyor musunuz?'),
                const SizedBox(height: 16),
                const Text(
                  'Müşteri Bilgileri (Opsiyonel)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Müşteri Adı',
                    prefixIcon: Icon(Icons.person),
                  ),
                  onSaved: (value) => customerName = value?.trim(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Şehir',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  onSaved: (value) => customerCity = value?.trim(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  onSaved: (value) => customerPhone = value?.trim(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'TC Kimlik No',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  onSaved: (value) => customerTcNo = value?.trim(),
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
              formKey.currentState?.save();
              setState(() {
                if (!car.isSold) {
                  // Satılma işlemi
                  final updatedCar = Car(
                    id: car.id,
                    brand: car.brand,
                    model: car.model,
                    package: car.package,
                    year: car.year,
                    price: car.price,
                    addedDate: car.addedDate,
                    isSold: true, // Doğrudan true olarak ayarla
                    soldDate: DateTime.now(), // Şimdiki zamanı ayarla
                    damageRecord: car.damageRecord,
                    description: car.description,
                    customerName: customerName,
                    customerCity: customerCity,
                    customerPhone: customerPhone,
                    customerTcNo: customerTcNo,
                  );
                  _saveCar(updatedCar);
                } else {
                  // Satış iptali
                  final updatedCar = Car(
                    id: car.id,
                    brand: car.brand,
                    model: car.model,
                    package: car.package,
                    year: car.year,
                    price: car.price,
                    addedDate: car.addedDate,
                    isSold: false,
                    soldDate: null,
                    damageRecord: car.damageRecord,
                    description: car.description,
                    customerName: null,
                    customerCity: null,
                    customerPhone: null,
                    customerTcNo: null,
                  );
                  _saveCar(updatedCar);
                }
              });
              Navigator.pop(context);
            },
            child: Text((car.isSold ? 'GERİ AL' : 'SATILDI').toUpperCase()),
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

  void _showCarDetails(Car car) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width *
              0.9, // Ekran genişliğinin %90'ı
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                0.9, // Ekran yüksekliğinin %90'ı
            minHeight:
                MediaQuery.of(context).size.height * 0.5, // Minimum yükseklik
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${car.brand} ${car.model}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (car.isSold)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
                const SizedBox(height: 24),
                // İçerik
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailItem(
                            'Paket', car.package ?? 'Belirtilmemiş'),
                        _buildDetailItem('Model Yılı', car.year),
                        _buildDetailItem('Fiyat', '${car.price} TL'),
                        _buildDetailItem(
                            'Hasar Kaydı',
                            car.damageRecord != '0'
                                ? '${car.damageRecord} TL'
                                : 'Yok'),
                        _buildDetailItem(
                            'Eklenme Tarihi', dateFormat.format(car.addedDate)),
                        if (car.description?.isNotEmpty ?? false)
                          _buildDetailItem('Açıklama', car.description!),
                        if (car.isSold) ...[
                          const Divider(height: 32),
                          Text(
                            'Müşteri Bilgileri',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailItem(
                              'Satış Tarihi', dateFormat.format(car.soldDate!)),
                          if (car.customerName?.isNotEmpty ?? false)
                            _buildDetailItem('Müşteri', car.customerName!),
                          if (car.customerCity?.isNotEmpty ?? false)
                            _buildDetailItem('Şehir', car.customerCity!),
                          if (car.customerPhone?.isNotEmpty ?? false)
                            _buildDetailItem('Telefon', car.customerPhone!),
                          if (car.customerTcNo?.isNotEmpty ?? false)
                            _buildDetailItem('TC Kimlik No', car.customerTcNo!),
                        ],
                      ],
                    ),
                  ),
                ),
                // Butonlar
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('KAPAT'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
