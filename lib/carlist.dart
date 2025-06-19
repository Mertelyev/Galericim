import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';
import 'car.dart';
import 'widgets/car_form.dart';
import 'widgets/paginated_list_view.dart';
import 'services/logging_service.dart';
import 'services/search_service.dart';
import 'services/notification_service.dart';

class CarListPage extends StatefulWidget {
  const CarListPage({super.key});

  @override
  State<CarListPage> createState() => _CarListPageState();
}

class _CarListPageState extends State<CarListPage> {
  final List<Car> cars = [];
  final dateFormat = DateFormat('dd.MM.yyyy');
  final dbHelper = DBHelper();
  final logger = LoggingService();
  final searchService = SearchService();
  final notificationService = NotificationService();
  List<Car> filteredCars = [];
  bool isLoading = true;
  bool isSearching = false;
  final searchController = TextEditingController();
  SearchOptions _currentSearchOptions = const SearchOptions();
  bool _isAdvancedSearchOpen = false;

  String? selectedBrand;
  String? selectedYear;
  RangeValues? priceRange;
  bool showOnlySoldCars = false;
  bool showOnlyInStock = false;  String? selectedFuelType;
  String? selectedTransmission;
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
    _initializeSearchService();
  }

  Future<void> _initializeSearchService() async {
    try {
      await searchService.buildIndex();
      logger.info('Search service initialized', tag: 'CarList');
    } catch (e, stackTrace) {
      logger.error('Failed to initialize search service',
          tag: 'CarList', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _loadCars() async {
    setState(() {
      isLoading = true;
    });

    try {
      logger.info('Loading cars from database', tag: 'CarList');
      final loadedCars = await dbHelper.getCars();
      setState(() {
        cars.clear();
        cars.addAll(loadedCars);
        filteredCars = loadedCars;
        isLoading = false;
      });

      await searchService.buildIndex();

      logger.info('Successfully loaded ${loadedCars.length} cars',
          tag: 'CarList');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load cars',
        tag: 'CarList',
        error: e,
        stackTrace: stackTrace,
      );

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
      await _loadCars();
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
    return [...filteredCars]..sort((a, b) {
        if (a.isSold != b.isSold) {
          return a.isSold ? 1 : -1;
        }
        return b.addedDate.compareTo(a.addedDate);
      });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      List<Car> results;
      if (query.isEmpty && _currentSearchOptions == const SearchOptions()) {
        results = cars;
      } else {
        results =
            await searchService.search(query, options: _currentSearchOptions);

        final stats = searchService.getStatistics();
        logger.info('Search performed', tag: 'CarList', data: {
          'query': query,
          'resultCount': results.length,
          'totalCars': stats.totalCarsIndexed,
          'isAdvanced': _currentSearchOptions != const SearchOptions(),
        });
      }

      if (mounted) {
        setState(() {
          filteredCars = results;
          isLoading = false;
        });
        if (query.isNotEmpty ||
            _currentSearchOptions != const SearchOptions()) {
          notificationService.showSuccess(
            '${results.length} araç bulundu',
          );
        }
      }
    } catch (e, stackTrace) {
      logger.error('Search failed',
          tag: 'CarList', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          filteredCars = _fallbackSearch(query);
          isLoading = false;
        });
        notificationService.showError(
          'Arama sırasında hata oluştu',
        );
      }
    }
  }

  List<Car> _fallbackSearch(String query) {
    if (query.isEmpty) return cars;
    final searchLower = query.toLowerCase().trim();
    return cars.where((car) {
      final brandMatch = car.brand.toLowerCase().contains(searchLower);
      final modelMatch = car.model.toLowerCase().contains(searchLower);
      final packageMatch =
          car.package?.toLowerCase().contains(searchLower) ?? false;

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
  }

  void _showAdvancedSearchDialog() async {
    final result = await showDialog<SearchOptions>(
      context: context,
      builder: (context) => _AdvancedSearchDialog(
        currentOptions: _currentSearchOptions,
        cars: cars,
      ),
    );

    if (result != null) {
      setState(() {
        _currentSearchOptions = result;
        _isAdvancedSearchOpen = true;
      });

      await _performSearch(searchController.text);
    }
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
                  hintText: 'Araç veya müşteri bilgilerinde ara...',
                  border: InputBorder.none,
                  hintStyle: Theme.of(context).brightness == Brightness.dark
                      ? TextStyle(color: Colors.white.withOpacity(0.7))
                      : TextStyle(color: Colors.black.withOpacity(0.7)),
                ),
                style: Theme.of(context).brightness == Brightness.dark
                    ? const TextStyle(color: Colors.white)
                    : const TextStyle(color: Colors.black),
                onChanged: _performSearch,
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
                  _currentSearchOptions = const SearchOptions();
                  _isAdvancedSearchOpen = false;
                  filteredCars = cars;
                });
              },
            ),
          IconButton.outlined(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton.outlined(
            icon: Icon(
              Icons.tune,
              color: _isAdvancedSearchOpen
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: _showAdvancedSearchDialog,
            tooltip: 'Gelişmiş Arama',
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
                  : PaginatedListView(
                      items: _getSortedCars(),
                      itemsPerPage: 15,
                      itemBuilder: (context, index, car) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildCarTile(car),
                        );
                      },
                      emptyWidget: Center(
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
                      ),
                    ),
            ),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        spacing: 8,
                        runSpacing: 8,
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
                                    padding: const EdgeInsets.only(top: 8),
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
                          _buildActionButtons(car),
                        ],
                      ),
                    ),
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
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
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
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          FilledButton(
            onPressed: () async {
              formKey.currentState?.save();
              final navigator = Navigator.of(context);
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
              navigator.pop();
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
                          final navigator = Navigator.of(context);
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);
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
                                    : null,                            fuelType: formData['fuelType']?.isNotEmpty == true
                                ? formData['fuelType']
                                : null,
                            transmission: formData['transmission']?.isNotEmpty == true
                                ? formData['transmission']
                                : null,
                          ));
                          if (!mounted) return;
                          navigator.pop();
                          scaffoldMessenger.showSnackBar(
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
                        final navigator = Navigator.of(context);
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
                          if (!mounted) return;
                          navigator.pop();
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
                              final navigator = Navigator.of(context);
                              final scaffoldMessenger =
                                  ScaffoldMessenger.of(context);
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
                                        : car.kilometers,                                fuelType:
                                    formData['fuelType']?.isNotEmpty == true
                                        ? formData['fuelType']
                                        : car.fuelType,
                                transmission:
                                    formData['transmission']?.isNotEmpty == true
                                        ? formData['transmission']
                                        : car.transmission,
                                customerName: car.customerName,
                                customerCity: car.customerCity,
                                customerPhone: car.customerPhone,
                                customerTcNo: car.customerTcNo,
                              );
                              await _saveCar(updatedCar);
                              if (!mounted) return;
                              navigator.pop();
                              scaffoldMessenger.showSnackBar(
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
                                'Kilometre', '${car.kilometers} KM'),                          if (car.fuelType != null)
                            _buildDetailRow('Yakıt Tipi', car.fuelType!),
                          if (car.transmission != null)
                            _buildDetailRow('Vites Tipi', car.transmission!),
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
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: SingleChildScrollView(
            child: CarForm(
              car: car,
              formKey: formKey,
              isCustomerForm: true,
              onSave: (values) {
                formData.addAll(values);
              },
            ),
          ),
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

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Müşteri bilgileri güncellendi'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
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

class _AdvancedSearchDialog extends StatefulWidget {
  final SearchOptions currentOptions;
  final List<Car> cars;

  const _AdvancedSearchDialog({
    required this.currentOptions,
    required this.cars,
  });

  @override
  State<_AdvancedSearchDialog> createState() => _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends State<_AdvancedSearchDialog> {
  late SearchOptions _options;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _minYearController;
  late TextEditingController _maxYearController;

  @override
  void initState() {
    super.initState();
    _options = widget.currentOptions;
    _minPriceController = TextEditingController(
      text: _options.minPrice?.toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: _options.maxPrice?.toString() ?? '',
    );
    _minYearController = TextEditingController(
      text: _options.minYear?.toString() ?? '',
    );
    _maxYearController = TextEditingController(
      text: _options.maxYear?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _minYearController.dispose();
    _maxYearController.dispose();
    super.dispose();
  }

  List<String> get _availableBrands {
    return widget.cars.map((car) => car.brand).toSet().toList()..sort();
  }

  List<String> get _availableFuelTypes {
    return widget.cars
        .where((car) => car.fuelType != null)
        .map((car) => car.fuelType!)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                  Icon(
                    Icons.tune,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gelişmiş Arama Seçenekleri',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _resetToDefaults,
                    child: const Text('Sıfırla'),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Fields Section
                    _buildSection(
                      'Arama Alanları',
                      Icons.search,
                      [
                        CheckboxListTile(
                          title: const Text('Marka'),
                          value: _options.searchInBrand,
                          onChanged: (value) => setState(() {
                            _options =
                                _options.copyWith(searchInBrand: value ?? true);
                          }),
                        ),
                        CheckboxListTile(
                          title: const Text('Model'),
                          value: _options.searchInModel,
                          onChanged: (value) => setState(() {
                            _options =
                                _options.copyWith(searchInModel: value ?? true);
                          }),
                        ),
                        CheckboxListTile(
                          title: const Text('Yıl'),
                          value: _options.searchInYear,
                          onChanged: (value) => setState(() {
                            _options =
                                _options.copyWith(searchInYear: value ?? true);
                          }),
                        ),
                        CheckboxListTile(
                          title: const Text('Yakıt Tipi'),
                          value: _options.searchInFuelType,
                          onChanged: (value) => setState(() {
                            _options = _options.copyWith(
                                searchInFuelType: value ?? true);
                          }),
                        ),
                        CheckboxListTile(
                          title: const Text('Müşteri Bilgileri'),
                          value: _options.searchInCustomer,
                          onChanged: (value) => setState(() {
                            _options = _options.copyWith(
                                searchInCustomer: value ?? true);
                          }),
                        ),
                        CheckboxListTile(
                          title: const Text('Açıklama'),
                          value: _options.searchInDescription,
                          onChanged: (value) => setState(() {
                            _options = _options.copyWith(
                                searchInDescription: value ?? true);
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Filters Section
                    _buildSection(
                      'Filtreler',
                      Icons.filter_list,
                      [
                        // Price Range
                        Text(
                          'Fiyat Aralığı',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minPriceController,
                                decoration: const InputDecoration(
                                  labelText: 'Min Fiyat',
                                  border: OutlineInputBorder(),
                                  suffixText: 'TL',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final price = double.tryParse(value);
                                  _options = _options.copyWith(minPrice: price);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _maxPriceController,
                                decoration: const InputDecoration(
                                  labelText: 'Max Fiyat',
                                  border: OutlineInputBorder(),
                                  suffixText: 'TL',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final price = double.tryParse(value);
                                  _options = _options.copyWith(maxPrice: price);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Year Range
                        Text(
                          'Yıl Aralığı',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minYearController,
                                decoration: const InputDecoration(
                                  labelText: 'Min Yıl',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final year = int.tryParse(value);
                                  _options = _options.copyWith(minYear: year);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _maxYearController,
                                decoration: const InputDecoration(
                                  labelText: 'Max Yıl',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final year = int.tryParse(value);
                                  _options = _options.copyWith(maxYear: year);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Sold Status
                        Text(
                          'Satış Durumu',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<SoldStatus?>(
                          value: _options.soldStatus,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: null, child: Text('Tüm Araçlar')),
                            DropdownMenuItem(
                                value: SoldStatus.available,
                                child: Text('Satılık Araçlar')),
                            DropdownMenuItem(
                                value: SoldStatus.sold,
                                child: Text('Satılan Araçlar')),
                          ],
                          onChanged: (value) => setState(() {
                            _options = _options.copyWith(soldStatus: value);
                          }),
                        ),
                        const SizedBox(height: 16),

                        // Brand Filter
                        Text(
                          'Markalar',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _availableBrands.map((brand) {
                            final isSelected = _options.brands.contains(brand);
                            return FilterChip(
                              label: Text(brand),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  final brands =
                                      List<String>.from(_options.brands);
                                  if (selected) {
                                    brands.add(brand);
                                  } else {
                                    brands.remove(brand);
                                  }
                                  _options = _options.copyWith(brands: brands);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Fuel Type Filter
                        Text(
                          'Yakıt Tipleri',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _availableFuelTypes.map((fuelType) {
                            final isSelected =
                                _options.fuelTypes.contains(fuelType);
                            return FilterChip(
                              label: Text(fuelType),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  final fuelTypes =
                                      List<String>.from(_options.fuelTypes);
                                  if (selected) {
                                    fuelTypes.add(fuelType);
                                  } else {
                                    fuelTypes.remove(fuelType);
                                  }
                                  _options =
                                      _options.copyWith(fuelTypes: fuelTypes);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sorting Section
                    _buildSection(
                      'Sıralama',
                      Icons.sort,
                      [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<SortBy>(
                                value: _options.sortBy,
                                decoration: const InputDecoration(
                                  labelText: 'Sırala',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: SortBy.addedDate,
                                      child: Text('Eklenme Tarihi')),
                                  DropdownMenuItem(
                                      value: SortBy.brand,
                                      child: Text('Marka')),
                                  DropdownMenuItem(
                                      value: SortBy.model,
                                      child: Text('Model')),
                                  DropdownMenuItem(
                                      value: SortBy.year, child: Text('Yıl')),
                                  DropdownMenuItem(
                                      value: SortBy.price,
                                      child: Text('Fiyat')),
                                  DropdownMenuItem(
                                      value: SortBy.soldDate,
                                      child: Text('Satış Tarihi')),
                                ],
                                onChanged: (value) => setState(() {
                                  _options = _options.copyWith(
                                      sortBy: value ?? SortBy.addedDate);
                                }),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<SortOrder>(
                                value: _options.sortOrder,
                                decoration: const InputDecoration(
                                  labelText: 'Sıra',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: SortOrder.ascending,
                                      child: Text('Artan')),
                                  DropdownMenuItem(
                                      value: SortOrder.descending,
                                      child: Text('Azalan')),
                                ],
                                onChanged: (value) => setState(() {
                                  _options = _options.copyWith(
                                      sortOrder: value ?? SortOrder.descending);
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Actions
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
                    onPressed: () => Navigator.pop(context, _options),
                    child: const Text('UYGULA'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
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
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  void _resetToDefaults() {
    setState(() {
      _options = const SearchOptions();
      _minPriceController.clear();
      _maxPriceController.clear();
      _minYearController.clear();
      _maxYearController.clear();
    });
  }
}
