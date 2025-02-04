import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlaması için eklendi
import 'db_helper.dart';
import 'car.dart';
import 'widgets/car_form.dart'; // Add this import

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

  // Filtreleme seçenekleri için
  String? selectedBrand;
  String? selectedYear;
  RangeValues? priceRange;
  bool showOnlySoldCars = false;
  bool showOnlyInStock = false; // Yeni eklenen değişken
  String? selectedFuelType; // Yeni değişken ekle

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
          // Araç bilgileri araması
          final brandMatch = car.brand.toLowerCase().contains(searchLower);
          final modelMatch = car.model.toLowerCase().contains(searchLower);
          final packageMatch =
              car.package?.toLowerCase().contains(searchLower) ?? false;

          // Müşteri bilgileri araması
          final customerNameMatch =
              car.customerName?.toLowerCase().contains(searchLower) ?? false;
          final customerCityMatch =
              car.customerCity?.toLowerCase().contains(searchLower) ?? false;
          final customerPhoneMatch =
              car.customerPhone?.toLowerCase().contains(searchLower) ?? false;
          final customerTcNoMatch =
              car.customerTcNo?.toLowerCase().contains(searchLower) ?? false;

          return brandMatch ||
              modelMatch ||
              packageMatch ||
              customerNameMatch ||
              customerCityMatch ||
              customerPhoneMatch ||
              customerTcNoMatch;
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

    // Tam eşleşmeler (en yüksek öncelik)
    if (car.brand.toLowerCase() == query) score += 100;
    if (car.model.toLowerCase() == query) score += 100;
    if (car.package?.toLowerCase() == query) score += 100;
    if (car.customerName?.toLowerCase() == query) score += 100;
    if (car.customerTcNo?.toLowerCase() == query) score += 100;

    // Başlangıç eşleşmeleri (orta öncelik)
    if (car.brand.toLowerCase().startsWith(query)) score += 50;
    if (car.model.toLowerCase().startsWith(query)) score += 50;
    if (car.package?.toLowerCase().startsWith(query) ?? false) score += 50;
    if (car.customerName?.toLowerCase().startsWith(query) ?? false) score += 50;
    if (car.customerCity?.toLowerCase().startsWith(query) ?? false) score += 50;

    // İçerik eşleşmeleri (düşük öncelik)
    if (car.brand.toLowerCase().contains(query)) score += 25;
    if (car.model.toLowerCase().contains(query)) score += 25;
    if (car.package?.toLowerCase().contains(query) ?? false) score += 25;
    if (car.customerName?.toLowerCase().contains(query) ?? false) score += 25;
    if (car.customerCity?.toLowerCase().contains(query) ?? false) score += 25;
    if (car.customerPhone?.toLowerCase().contains(query) ?? false) score += 25;
    if (car.customerTcNo?.toLowerCase().contains(query) ?? false) score += 25;

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
                  hintText:
                      'Araç veya müşteri bilgilerinde ara...', // Hint text güncellendi
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
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  const SizedBox(height: 12),
                  // Model yılı, kilometre ve yakıt bilgisi aynı satırda
                  Row(
                    children: [
                      Text(
                        car.year,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.white70 : null,
                            ),
                      ),
                      if (car.kilometers != null) ...[
                        Text(
                          ' • ${car.kilometers} KM',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.white70 : null,
                                  ),
                        ),
                      ],
                      if (car.fuelType != null) ...[
                        Text(
                          ' • ${car.fuelType}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.white70 : null,
                                  ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    '${car.price} TL',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (car.damageRecord != '0')
                    Text(
                      'Hasar Kaydı: ${car.damageRecord} TL',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 8),
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
                  // Açıklama bölümü
                  if (car.description != null &&
                      car.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
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
                  if (car.isSold)
                    Flexible(
                      child: IconButton(
                        icon: const Icon(Icons.person),
                        tooltip: 'Müşteri Bilgileri',
                        onPressed: () => _showCustomerDetails(car),
                      ),
                    ),
                  Flexible(
                    child: IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Düzenle',
                      onPressed: () => _showEditCarDialog(car),
                    ),
                  ),
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
    final Map<String, String> formData = {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Satış Durumu Değişikliği'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(car.isSold
                ? 'Bu aracın satıldı işaretini kaldırmak istiyor musunuz?'
                : 'Bu aracı satıldı olarak işaretlemek istiyor musunuz?'),
            const SizedBox(height: 16),
            if (!car.isSold) ...[
              const Text(
                'Müşteri Bilgileri (Opsiyonel)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CarForm(
                formKey: formKey,
                isCustomerForm: true,
                onSave: (values) {
                  formData.addAll(values);
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          FilledButton(
            onPressed: () {
              formKey.currentState?.save();
              final updatedCar = car.isSold
                  ? Car(
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
                    )
                  : Car(
                      id: car.id,
                      brand: car.brand,
                      model: car.model,
                      package: car.package,
                      year: car.year,
                      price: car.price,
                      addedDate: car.addedDate,
                      isSold: true,
                      soldDate: DateTime.now(),
                      damageRecord: car.damageRecord,
                      description: car.description,
                      customerName: formData['customerName'],
                      customerCity: formData['customerCity'],
                      customerPhone: formData['customerPhone'],
                      customerTcNo: formData['customerTcNo'],
                    );
              _saveCar(updatedCar);
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
    final Map<String, String> formData = {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Araç Ekle'),
        content: CarForm(
          formKey: formKey,
          onSave: (values) {
            formData.addAll(values);
          },
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
                  brand: formData['brand'] ?? '',
                  model: formData['model'] ?? '',
                  package: formData['package']?.isNotEmpty == true
                      ? formData['package']
                      : null,
                  year: formData['year'] ?? '',
                  price: formData['price'] ?? '',
                  addedDate: DateTime.now(),
                  damageRecord: formData['damageRecord'] ?? '0',
                  description: formData['description']?.isNotEmpty == true
                      ? formData['description']
                      : null,
                  kilometers: formData['kilometers']?.isNotEmpty == true
                      ? formData['kilometers']
                      : null,
                  fuelType: formData['fuelType']?.isNotEmpty == true
                      ? formData['fuelType']
                      : null,
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

  void _showEditCarDialog(Car car) {
    final formKey = GlobalKey<FormState>();
    final Map<String, String> formData = {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Araç Bilgilerini Düzenle'),
        content: CarForm(
          car: car, // Mevcut araç bilgilerini form'a geç
          formKey: formKey,
          onSave: (values) {
            formData.addAll(values);
          },
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

                final updatedCar = Car(
                  id: car.id,
                  brand: formData['brand'] ?? car.brand,
                  model: formData['model'] ?? car.model,
                  package: formData['package']?.isNotEmpty == true
                      ? formData['package']
                      : car.package,
                  year: formData['year'] ?? car.year,
                  price: formData['price'] ?? car.price,
                  addedDate: car.addedDate,
                  isSold: car.isSold,
                  soldDate: car.soldDate,
                  damageRecord: formData['damageRecord'] ?? car.damageRecord,
                  description: formData['description']?.isNotEmpty == true
                      ? formData['description']
                      : car.description,
                  kilometers: formData['kilometers']?.isNotEmpty == true
                      ? formData['kilometers']
                      : car.kilometers,
                  fuelType: formData['fuelType']?.isNotEmpty == true
                      ? formData['fuelType']
                      : car.fuelType,
                  customerName: car.customerName,
                  customerCity: car.customerCity,
                  customerPhone: car.customerPhone,
                  customerTcNo: car.customerTcNo,
                );

                _saveCar(updatedCar);
                Navigator.pop(context);

                // Kullanıcıya bilgi ver
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Araç bilgileri güncellendi'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('GÜNCELLE'),
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
                        if (car.kilometers != null)
                          _buildDetailItem('Kilometre', '${car.kilometers} KM'),
                        if (car.fuelType != null)
                          _buildDetailItem('Yakıt Tipi', car.fuelType!),
                      ],
                    ),
                  ),
                ),
                // Butonlar
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('KAPAT'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditCarDialog(car);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('DÜZENLE'),
                    ),
                  ],
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

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Filtreler'),
                trailing: TextButton(
                  onPressed: () {
                    setState(() {
                      selectedBrand = null;
                      selectedYear = null;
                      priceRange = null;
                      showOnlySoldCars = false;
                      showOnlyInStock = false;
                      selectedFuelType = null; // Sıfırla
                    });
                  },
                  child: const Text('Temizle'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedBrand,
                      items: _getUniqueBrands(),
                      onChanged: (value) =>
                          setState(() => selectedBrand = value),
                      decoration: const InputDecoration(
                        labelText: 'Marka',
                      ),
                    ),
                    // Yeni eklenen switch'ler
                    SwitchListTile(
                      title: const Text('Sadece Stoktaki Araçlar'),
                      subtitle: const Text('Satılmamış araçları göster'),
                      value: showOnlyInStock,
                      onChanged: (value) {
                        setState(() {
                          showOnlyInStock = value;
                          if (value) {
                            showOnlySoldCars =
                                false; // Biri seçildiğinde diğerini kapat
                          }
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Sadece Satılan Araçlar'),
                      subtitle: const Text('Satılmış araçları göster'),
                      value: showOnlySoldCars,
                      onChanged: (value) {
                        setState(() {
                          showOnlySoldCars = value;
                          if (value) {
                            showOnlyInStock =
                                false; // Biri seçildiğinde diğerini kapat
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedFuelType,
                      items: _getUniqueFuelTypes(),
                      onChanged: (value) =>
                          setState(() => selectedFuelType = value),
                      decoration: const InputDecoration(
                        labelText: 'Yakıt Tipi',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Filtreleri Uygula'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getUniqueBrands() {
    final brands = cars.map((car) => car.brand).toSet().toList()..sort();
    return [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('Tümü'),
      ),
      ...brands.map((brand) => DropdownMenuItem<String>(
            value: brand,
            child: Text(brand),
          )),
    ];
  }

  List<DropdownMenuItem<String>> _getUniqueFuelTypes() {
    final fuelTypes = cars
        .where((car) => car.fuelType != null)
        .map((car) => car.fuelType!)
        .toSet()
        .toList()
      ..sort();

    return [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('Tümü'),
      ),
      ...fuelTypes.map((type) => DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          )),
    ];
  }

  void _applyFilters() {
    setState(() {
      filteredCars = cars.where((car) {
        // Marka filtresi
        if (selectedBrand != null && car.brand != selectedBrand) {
          return false;
        }

        // Yakıt tipi filtresi
        if (selectedFuelType != null && car.fuelType != selectedFuelType) {
          return false;
        }

        // Stok durumu filtreleri
        if (showOnlyInStock && car.isSold) {
          return false;
        }
        if (showOnlySoldCars && !car.isSold) {
          return false;
        }

        // Fiyat aralığı filtresi
        if (priceRange != null) {
          final carPrice = double.tryParse(car.price.replaceAll(',', '')) ?? 0;
          if (carPrice < priceRange!.start || carPrice > priceRange!.end) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _showCustomerDetails(Car car) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Müşteri Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Müşteri', car.customerName ?? 'Belirtilmemiş'),
            _buildDetailItem('Şehir', car.customerCity ?? 'Belirtilmemiş'),
            _buildDetailItem('Telefon', car.customerPhone ?? 'Belirtilmemiş'),
            _buildDetailItem(
                'TC Kimlik No', car.customerTcNo ?? 'Belirtilmemiş'),
            _buildDetailItem('Satış Tarihi', dateFormat.format(car.soldDate!)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('KAPAT'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showUpdateCustomerDialog(car);
            },
            icon: const Icon(Icons.edit),
            label: const Text('BİLGİLERİ GÜNCELLE'),
          ),
        ],
      ),
    );
  }

  void _showUpdateCustomerDialog(Car car) {
    final formKey = GlobalKey<FormState>();
    final Map<String, String> formData = {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Müşteri Bilgilerini Güncelle'),
        content: CarForm(
          car: car,
          formKey: formKey,
          isCustomerForm: true,
          onSave: (values) {
            formData.addAll(values);
          },
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

                final updatedCar = Car(
                  id: car.id,
                  brand: car.brand,
                  model: car.model,
                  package: car.package,
                  year: car.year,
                  price: car.price,
                  addedDate: car.addedDate,
                  isSold: car.isSold,
                  soldDate: car.soldDate,
                  damageRecord: car.damageRecord,
                  description: car.description,
                  kilometers: car.kilometers,
                  fuelType: car.fuelType,
                  customerName: formData['customerName'],
                  customerCity: formData['customerCity'],
                  customerPhone: formData['customerPhone'],
                  customerTcNo: formData['customerTcNo'],
                );

                _saveCar(updatedCar);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Müşteri bilgileri güncellendi'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('GÜNCELLE'),
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
