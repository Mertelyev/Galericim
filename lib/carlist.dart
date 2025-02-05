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
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  String? selectedMonth;
  String? selectedFilterYear;

  List<String> get _months => [
        'Ocak',
        'Şubat',
        'Mart',
        'Nisan',
        'Mayıs',
        'Haziran',
        'Temmuz',
        'Ağustos',
        'Eylül',
        'Ekim',
        'Kasım',
        'Aralık'
      ];

  List<String> get _years {
    final years = <String>[];
    final currentYear = DateTime.now().year;
    for (int year = currentYear; year >= 2000; year--) {
      years.add(year.toString());
    }
    return years;
  }

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
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.5),
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        actions: [
          if (isSearching)
            IconButton.outlined(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isSearching = false;
                  searchController.clear();
                  filteredCars = cars;
                });
              },
            ),
          IconButton.outlined(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          const SizedBox(width: 8),
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
      // Floating Action Buttons için daha modern bir yerleşim
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: FloatingActionButton(
                heroTag: 'searchFAB',
                onPressed: () {
                  setState(() {
                    isSearching = true;
                  });
                },
                elevation: 4,
                child: const Icon(Icons.search),
              ),
            ),
            Padding(
              // Sağ tarafa padding eklendi
              padding: const EdgeInsets.only(right: 12),
              child: FloatingActionButton.extended(
                heroTag: 'addFAB',
                onPressed: () => _showAddCarDialog(),
                elevation: 4,
                icon: const Icon(Icons.add),
                label: const Text('Araç Ekle'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildCarTile(Car car) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCarDetails(car),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              // Header kısmı
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Araç ikonu
                    CircleAvatar(
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
                    const SizedBox(width: 16),
                    // Araç başlık bilgileri - Model yazısını normal weight yap
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 4,
                                  children: [
                                    Text(
                                      car.brand,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const Text('-'),
                                    Text(
                                      car.model,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ],
                                ),
                              ),
                              if (car.isSold)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'SATILDI',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (car.package != null && car.package!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                car.package!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content kısmı
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Özellikler satırı - Row yerine Wrap kullanıyoruz
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        spacing: 8, // Öğeler arası yatay boşluk
                        runSpacing: 8, // Satırlar arası dikey boşluk
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildFeatureItem(
                            Icons.calendar_today_outlined,
                            car.year,
                          ),
                          if (car.kilometers != null) ...[
                            _buildFeatureItemWithDivider(
                              Icons.speed_outlined,
                              '${car.kilometers} KM',
                            ),
                          ],
                          if (car.fuelType != null) ...[
                            _buildFeatureItemWithDivider(
                              Icons.local_gas_station_outlined,
                              car.fuelType!,
                            ),
                          ],
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${car.price} TL',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                                if (car.damageRecord != '0')
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8), // Üst boşluğu azalt
                                    child: Text(
                                      'Hasar: ${car.damageRecord} TL',
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // İşlem butonları
                          _buildActionButtons(car),
                        ],
                      ),
                    ),
                    // Tarih bilgileri
                    const SizedBox(height: 8),
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text('Eklenme: ${dateFormat.format(car.addedDate)}'),
                          if (car.isSold && car.soldDate != null) ...[
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.sell_outlined,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text('Satış: ${dateFormat.format(car.soldDate!)}'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            onPressed: () async {
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
              await _saveCar(updatedCar);
              if (!mounted) return;
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
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            minHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car_filled,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Yeni Araç Ekle',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: CarForm(
                    formKey: formKey,
                    onSave: (values) => formData.addAll(values),
                  ),
                ),
              ),
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İPTAL'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          formKey.currentState?.save();
                          await _saveCar(Car(
                            brand: formData['brand'] ?? '',
                            model: formData['model'] ?? '',
                            package: formData['package']?.isNotEmpty == true
                                ? formData['package']
                                : null,
                            year: formData['year'] ?? '',
                            price: formData['price'] ?? '',
                            addedDate: formData['addedDate'] != null
                                ? DateTime.parse(formData['addedDate']!)
                                : DateTime.now(),
                            damageRecord: formData['damageRecord'] ?? '0',
                            description:
                                formData['description']?.isNotEmpty == true
                                    ? formData['description']
                                    : null,
                            kilometers:
                                formData['kilometers']?.isNotEmpty == true
                                    ? formData['kilometers']
                                    : null,
                            fuelType: formData['fuelType']?.isNotEmpty == true
                                ? formData['fuelType']
                                : null,
                          ));
                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Araç başarıyla eklendi'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('EKLE'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCarDialog(Car car) {
    final formKey = GlobalKey<FormState>();
    final Map<String, String> formData = {};

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            minHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Araç Düzenle',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${car.brand} ${car.model}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: CarForm(
                    car: car,
                    formKey: formKey,
                    onSave: (values) => formData.addAll(values),
                  ),
                ),
              ),
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Silme Onayı'),
                            content: const Text(
                                'Bu aracı silmek istediğinize emin misiniz?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('VAZGEÇ'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('SİL'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && car.id != null) {
                          await _deleteCar(car.id!);
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('SİL'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İPTAL'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
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
                                damageRecord: formData['damageRecord'] ??
                                    car.damageRecord,
                                description:
                                    formData['description']?.isNotEmpty == true
                                        ? formData['description']
                                        : car.description,
                                kilometers:
                                    formData['kilometers']?.isNotEmpty == true
                                        ? formData['kilometers']
                                        : car.kilometers,
                                fuelType:
                                    formData['fuelType']?.isNotEmpty == true
                                        ? formData['fuelType']
                                        : car.fuelType,
                                customerName: car.customerName,
                                customerCity: car.customerCity,
                                customerPhone: car.customerPhone,
                                customerTcNo: car.customerTcNo,
                              );
                              await _saveCar(updatedCar);
                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Araç bilgileri güncellendi'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('KAYDET'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCarDetails(Car car) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            minHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${car.brand} ${car.model}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (car.package != null && car.package!.isNotEmpty)
                            Text(
                              car.package!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    if (car.isSold)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'SATILDI',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Temel Bilgiler
                      _buildDetailSection(
                        title: 'Temel Bilgiler',
                        icon: Icons.info_outline,
                        children: [
                          _buildDetailRow('Model Yılı', car.year),
                          _buildDetailRow('Fiyat', '${car.price} TL',
                              isHighlighted: true),
                          if (car.kilometers != null)
                            _buildDetailRow(
                                'Kilometre', '${car.kilometers} KM'),
                          if (car.fuelType != null)
                            _buildDetailRow('Yakıt Tipi', car.fuelType!),
                          _buildDetailRow(
                            'Hasar Kaydı',
                            car.damageRecord != '0'
                                ? '${car.damageRecord} TL'
                                : 'Yok',
                            textColor: car.damageRecord != '0'
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tarih Bilgileri
                      _buildDetailSection(
                        title: 'Tarih Bilgileri',
                        icon: Icons.calendar_today,
                        children: [
                          _buildDetailRow('Eklenme Tarihi',
                              dateFormat.format(car.addedDate)),
                          if (car.isSold && car.soldDate != null)
                            _buildDetailRow('Satış Tarihi',
                                dateFormat.format(car.soldDate!)),
                        ],
                      ),

                      // Açıklama
                      if (car.description?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 24),
                        _buildDetailSection(
                          title: 'Açıklama',
                          icon: Icons.description_outlined,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(car.description!),
                            ),
                          ],
                        ),
                      ],

                      // Müşteri Bilgileri
                      if (car.isSold) ...[
                        const SizedBox(height: 24),
                        _buildDetailSection(
                          title: 'Müşteri Bilgileri',
                          icon: Icons.person_outline,
                          children: [
                            _buildDetailRow(
                                'Müşteri', car.customerName ?? 'Belirtilmemiş'),
                            _buildDetailRow(
                                'Şehir', car.customerCity ?? 'Belirtilmemiş'),
                            _buildDetailRow('Telefon',
                                car.customerPhone ?? 'Belirtilmemiş'),
                            _buildDetailRow('TC Kimlik No',
                                car.customerTcNo ?? 'Belirtilmemiş'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlighted = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: isHighlighted
                  ? Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      )
                  : Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üst kısım
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Filtreler',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          selectedBrand = null;
                          selectedYear = null;
                          priceRange = null;
                          showOnlySoldCars = false;
                          showOnlyInStock = false;
                          selectedFuelType = null;
                          selectedMonth = null;
                          selectedFilterYear = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Temizle'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Durum filtreleri
                      Text(
                        'Araç Durumu',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Sadece stoktaki araçları göster'),
                        value: showOnlyInStock,
                        onChanged: (value) {
                          setState(() {
                            showOnlyInStock = value ?? false;
                            if (value == true) {
                              showOnlySoldCars = false;
                            }
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      CheckboxListTile(
                        title: const Text('Sadece satılan araçları göster'),
                        value: showOnlySoldCars,
                        onChanged: (value) {
                          setState(() {
                            showOnlySoldCars = value ?? false;
                            if (value == true) {
                              showOnlyInStock = false;
                            }
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 16),
                      const Divider(),

                      // Marka ve yakıt tipi filtreleri
                      Text(
                        'Araç Özellikleri',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        label: 'Marka',
                        value: selectedBrand,
                        items: _getUniqueBrands(),
                        onChanged: (value) =>
                            setState(() => selectedBrand = value),
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        label: 'Yakıt Tipi',
                        value: selectedFuelType,
                        items: _getUniqueFuelTypes(),
                        onChanged: (value) =>
                            setState(() => selectedFuelType = value),
                      ),
                      const SizedBox(height: 24),

                      // Tarih filtreleri
                      Text(
                        'Tarih Filtreleri',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: 'Ay',
                              value: selectedMonth,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Tüm Aylar'),
                                ),
                                ..._months.asMap().entries.map((entry) {
                                  return DropdownMenuItem(
                                    value: (entry.key + 1).toString(),
                                    child: Text(entry.value),
                                  );
                                }),
                              ],
                              onChanged: (value) =>
                                  setState(() => selectedMonth = value),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Yıl',
                              value: selectedFilterYear,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Tüm Yıllar'),
                                ),
                                ..._years.map((year) => DropdownMenuItem(
                                      value: year,
                                      child: Text(year),
                                    )),
                              ],
                              onChanged: (value) =>
                                  setState(() => selectedFilterYear = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // Uygula butonu
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('FİLTRELERİ UYGULA'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      icon: const Icon(Icons.keyboard_arrow_down),
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

        // Ay ve yıl filtresi
        if (selectedMonth != null || selectedFilterYear != null) {
          final carDate = car.isSold ? car.soldDate! : car.addedDate;

          if (selectedMonth != null &&
              carDate.month.toString() != selectedMonth) {
            return false;
          }

          if (selectedFilterYear != null &&
              carDate.year.toString() != selectedFilterYear) {
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
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 28,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.customerName ?? 'İsimsiz Müşteri',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (car.customerCity != null)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                car.customerCity!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCustomerInfoRow(
                        Icons.phone,
                        'Telefon',
                        car.customerPhone ?? 'Belirtilmemiş',
                      ),
                      const Divider(height: 24),
                      _buildCustomerInfoRow(
                        Icons.badge_outlined,
                        'TC Kimlik No',
                        car.customerTcNo ?? 'Belirtilmemiş',
                      ),
                      const Divider(height: 24),
                      _buildCustomerInfoRow(
                        Icons.sell,
                        'Satış Tarihi',
                        dateFormat.format(car.soldDate!),
                        isHighlighted: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Araç Bilgisi
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Satın Alınan Araç',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                          Text(
                            '${car.brand} ${car.model}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        car.price,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('KAPAT'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showUpdateCustomerDialog(car);
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
    );
  }

  Widget _buildCustomerInfoRow(IconData icon, String label, String value,
      {bool isHighlighted = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isHighlighted
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isHighlighted ? FontWeight.bold : null,
                      color: isHighlighted
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
              ),
            ],
          ),
        ),
      ],
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
            onPressed: () async {
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

                await _saveCar(updatedCar);
                if (!mounted) return;
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

  void _showDeleteConfirmation(Car car) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aracı Sil'),
        content: Text(
            '${car.brand} ${car.model} aracını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () async {
              // Close dialog first
              Navigator.pop(dialogContext);
              // Then handle deletion
              if (car.id != null) {
                await _deleteCar(car.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Araç başarıyla silindi'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('SİL'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Car car) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (car.isSold)
          IconButton.outlined(
            icon: const Icon(Icons.person_outline),
            onPressed: () => _showCustomerDetails(car),
            tooltip: 'Müşteri Bilgileri',
          ),
        const SizedBox(width: 8),
        IconButton.outlined(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _showEditCarDialog(car),
          tooltip: 'Düzenle',
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          icon: Icon(
            car.isSold ? Icons.undo : Icons.check_circle_outline,
          ),
          onPressed: () => _showToggleSoldDialog(car),
          tooltip:
              car.isSold ? 'Satış durumunu geri al' : 'Satıldı olarak işaretle',
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _showDeleteConfirmation(car),
          tooltip: 'Sil',
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget _buildFeatureItemWithDivider(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 16,
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color:
              Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
        ),
        _buildFeatureItem(icon, text),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
