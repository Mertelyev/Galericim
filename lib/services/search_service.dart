import 'dart:async';
import '../car.dart';
import '../db_helper.dart';
import 'logging_service.dart';

class SearchService {
  static final _logger = LoggingService();
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  // In-memory search index for fast searching
  final Map<String, Set<int>> _brandIndex = {};
  final Map<String, Set<int>> _modelIndex = {};
  final Map<String, Set<int>> _yearIndex = {};
  final Map<String, Set<int>> _fuelTypeIndex = {};
  final Map<String, Set<int>> _colorIndex = {};
  final Map<String, Set<int>> _transmissionIndex = {};
  final Map<String, Set<int>> _customerIndex = {};
  final Map<String, Set<int>> _descriptionIndex = {};

  final Map<int, Car> _carCache = {};
  bool _isIndexed = false;
  DateTime? _lastIndexUpdate;

  /// Builds or rebuilds the search index
  Future<void> buildIndex() async {
    try {
      _logger.info('Building search index', tag: 'Search');
      final stopwatch = Stopwatch()..start();

      // Clear existing indices
      _clearIndices();

      final dbHelper = DBHelper();
      final cars = await dbHelper.getCars();

      for (final car in cars) {
        if (car.id != null) {
          _indexCar(car);
        }
      }

      _isIndexed = true;
      _lastIndexUpdate = DateTime.now();

      stopwatch.stop();
      _logger.info('Search index built successfully', tag: 'Search', data: {
        'totalCars': cars.length,
        'buildTimeMs': stopwatch.elapsedMilliseconds,
        'indexSize': _carCache.length,
      });
    } catch (e, stackTrace) {
      _logger.error('Failed to build search index',
          tag: 'Search', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Adds a car to the search index
  void addToIndex(Car car) {
    if (car.id != null) {
      _indexCar(car);
      _logger.debug('Car added to search index', tag: 'Search', data: {
        'carId': car.id,
        'brand': car.brand,
        'model': car.model,
      });
    }
  }

  /// Removes a car from the search index
  void removeFromIndex(int carId) {
    final car = _carCache[carId];
    if (car != null) {
      _removeCarFromIndex(car);
      _carCache.remove(carId);
      _logger.debug('Car removed from search index', tag: 'Search', data: {
        'carId': carId,
      });
    }
  }

  /// Updates a car in the search index
  void updateIndex(Car car) {
    if (car.id != null) {
      // Remove old version if exists
      removeFromIndex(car.id!);
      // Add new version
      addToIndex(car);
      _logger.debug('Car updated in search index', tag: 'Search', data: {
        'carId': car.id,
      });
    }
  }

  /// Performs a comprehensive search across all indexed fields
  Future<List<Car>> search(
    String query, {
    SearchOptions? options,
  }) async {
    try {
      if (!_isIndexed) {
        await buildIndex();
      }

      if (query.isEmpty) {
        return _getAllCars(options);
      }

      _logger.debug('Performing search', tag: 'Search', data: {
        'query': query,
        'options': options?.toString(),
      });

      final stopwatch = Stopwatch()..start();
      final searchTerms = _normalizeSearchTerms(query);
      final matchingCarIds = <int>{};

      // Search in different fields based on options
      final searchOptions = options ?? const SearchOptions();

      if (searchOptions.searchInBrand) {
        matchingCarIds.addAll(_searchInIndex(_brandIndex, searchTerms));
      }

      if (searchOptions.searchInModel) {
        matchingCarIds.addAll(_searchInIndex(_modelIndex, searchTerms));
      }

      if (searchOptions.searchInYear) {
        matchingCarIds.addAll(_searchInIndex(_yearIndex, searchTerms));
      }

      if (searchOptions.searchInFuelType) {
        matchingCarIds.addAll(_searchInIndex(_fuelTypeIndex, searchTerms));
      }

      if (searchOptions.searchInColor) {
        matchingCarIds.addAll(_searchInIndex(_colorIndex, searchTerms));
      }

      if (searchOptions.searchInTransmission) {
        matchingCarIds.addAll(_searchInIndex(_transmissionIndex, searchTerms));
      }

      if (searchOptions.searchInCustomer) {
        matchingCarIds.addAll(_searchInIndex(_customerIndex, searchTerms));
      }

      if (searchOptions.searchInDescription) {
        matchingCarIds.addAll(_searchInIndex(_descriptionIndex, searchTerms));
      }

      // Get cars and apply filters
      List<Car> results = matchingCarIds
          .map((id) => _carCache[id])
          .where((car) => car != null)
          .cast<Car>()
          .toList();

      results = _applyFilters(results, searchOptions);
      results =
          _sortResults(results, searchOptions.sortBy, searchOptions.sortOrder);

      stopwatch.stop();
      _logger.info('Search completed', tag: 'Search', data: {
        'query': query,
        'resultCount': results.length,
        'searchTimeMs': stopwatch.elapsedMilliseconds,
      });

      return results;
    } catch (e, stackTrace) {
      _logger.error('Search failed',
          tag: 'Search', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Performs a quick search in brand and model only (for autocomplete)
  Future<List<String>> quickSearch(String query, {int limit = 10}) async {
    try {
      if (!_isIndexed) {
        await buildIndex();
      }

      if (query.isEmpty) return [];

      final suggestions = <String>{};
      final normalizedQuery = _normalizeText(query);

      // Search in brands
      for (final brand in _brandIndex.keys) {
        if (brand.contains(normalizedQuery)) {
          suggestions.add(brand);
        }
      }

      // Search in models
      for (final model in _modelIndex.keys) {
        if (model.contains(normalizedQuery)) {
          suggestions.add(model);
        }
      }

      final result = suggestions.take(limit).toList()..sort();

      _logger.debug('Quick search completed', tag: 'Search', data: {
        'query': query,
        'suggestionCount': result.length,
      });

      return result;
    } catch (e, stackTrace) {
      _logger.error('Quick search failed',
          tag: 'Search', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Gets search statistics
  SearchStatistics getStatistics() {
    return SearchStatistics(
      isIndexed: _isIndexed,
      lastIndexUpdate: _lastIndexUpdate,
      totalCarsIndexed: _carCache.length,
      indexSizes: {
        'brand': _brandIndex.length,
        'model': _modelIndex.length,
        'year': _yearIndex.length,
        'fuelType': _fuelTypeIndex.length,
        'color': _colorIndex.length,
        'transmission': _transmissionIndex.length,
        'customer': _customerIndex.length,
        'description': _descriptionIndex.length,
      },
    );
  }

  // Private methods

  void _clearIndices() {
    _brandIndex.clear();
    _modelIndex.clear();
    _yearIndex.clear();
    _fuelTypeIndex.clear();
    _colorIndex.clear();
    _transmissionIndex.clear();
    _customerIndex.clear();
    _descriptionIndex.clear();
    _carCache.clear();
  }

  void _indexCar(Car car) {
    if (car.id == null) return;

    _carCache[car.id!] = car;

    // Index brand
    _addToIndex(_brandIndex, _normalizeText(car.brand), car.id!);

    // Index model
    _addToIndex(_modelIndex, _normalizeText(car.model), car.id!);

    // Index year
    _addToIndex(_yearIndex, car.year, car.id!);

    // Index fuel type
    if (car.fuelType != null) {
      _addToIndex(_fuelTypeIndex, _normalizeText(car.fuelType!), car.id!);
    }

    // Index color
    if (car.color != null) {
      _addToIndex(_colorIndex, _normalizeText(car.color!), car.id!);
    }

    // Index transmission
    if (car.transmission != null) {
      _addToIndex(
          _transmissionIndex, _normalizeText(car.transmission!), car.id!);
    }

    // Index customer info
    if (car.customerName != null) {
      _addToIndex(_customerIndex, _normalizeText(car.customerName!), car.id!);
    }
    if (car.customerCity != null) {
      _addToIndex(_customerIndex, _normalizeText(car.customerCity!), car.id!);
    }

    // Index description
    if (car.description != null) {
      final words = _normalizeText(car.description!).split(' ');
      for (final word in words) {
        if (word.length > 2) {
          // Only index words longer than 2 characters
          _addToIndex(_descriptionIndex, word, car.id!);
        }
      }
    }
  }

  void _removeCarFromIndex(Car car) {
    if (car.id == null) return;

    _removeFromIndex(_brandIndex, _normalizeText(car.brand), car.id!);
    _removeFromIndex(_modelIndex, _normalizeText(car.model), car.id!);
    _removeFromIndex(_yearIndex, car.year, car.id!);

    if (car.fuelType != null) {
      _removeFromIndex(_fuelTypeIndex, _normalizeText(car.fuelType!), car.id!);
    }
    if (car.color != null) {
      _removeFromIndex(_colorIndex, _normalizeText(car.color!), car.id!);
    }
    if (car.transmission != null) {
      _removeFromIndex(
          _transmissionIndex, _normalizeText(car.transmission!), car.id!);
    }
    if (car.customerName != null) {
      _removeFromIndex(
          _customerIndex, _normalizeText(car.customerName!), car.id!);
    }
    if (car.customerCity != null) {
      _removeFromIndex(
          _customerIndex, _normalizeText(car.customerCity!), car.id!);
    }
    if (car.description != null) {
      final words = _normalizeText(car.description!).split(' ');
      for (final word in words) {
        if (word.length > 2) {
          _removeFromIndex(_descriptionIndex, word, car.id!);
        }
      }
    }
  }

  void _addToIndex(Map<String, Set<int>> index, String key, int carId) {
    index.putIfAbsent(key, () => <int>{}).add(carId);
  }

  void _removeFromIndex(Map<String, Set<int>> index, String key, int carId) {
    index[key]?.remove(carId);
    if (index[key]?.isEmpty == true) {
      index.remove(key);
    }
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .trim();
  }

  List<String> _normalizeSearchTerms(String query) {
    return _normalizeText(query)
        .split(' ')
        .where((term) => term.isNotEmpty)
        .toList();
  }

  Set<int> _searchInIndex(
      Map<String, Set<int>> index, List<String> searchTerms) {
    final results = <int>{};

    for (final term in searchTerms) {
      for (final key in index.keys) {
        if (key.contains(term)) {
          results.addAll(index[key]!);
        }
      }
    }

    return results;
  }

  List<Car> _getAllCars(SearchOptions? options) {
    List<Car> results = _carCache.values.toList();

    if (options != null) {
      results = _applyFilters(results, options);
      results = _sortResults(results, options.sortBy, options.sortOrder);
    }

    return results;
  }

  List<Car> _applyFilters(List<Car> cars, SearchOptions options) {
    return cars.where((car) {
      // Price range filter
      if (options.minPrice != null) {
        final price =
            double.tryParse(car.price.replaceAll(RegExp(r'[^\d.]'), ''));
        if (price == null || price < options.minPrice!) return false;
      }

      if (options.maxPrice != null) {
        final price =
            double.tryParse(car.price.replaceAll(RegExp(r'[^\d.]'), ''));
        if (price == null || price > options.maxPrice!) return false;
      }

      // Year range filter
      if (options.minYear != null) {
        final year = int.tryParse(car.year);
        if (year == null || year < options.minYear!) return false;
      }

      if (options.maxYear != null) {
        final year = int.tryParse(car.year);
        if (year == null || year > options.maxYear!) return false;
      }

      // Sold status filter
      if (options.soldStatus != null) {
        if (options.soldStatus == SoldStatus.sold && !car.isSold) return false;
        if (options.soldStatus == SoldStatus.available && car.isSold) {
          return false;
        }
      }

      // Fuel type filter
      if (options.fuelTypes.isNotEmpty) {
        if (car.fuelType == null || !options.fuelTypes.contains(car.fuelType)) {
          return false;
        }
      }

      // Brand filter
      if (options.brands.isNotEmpty) {
        if (!options.brands.contains(car.brand)) return false;
      }

      return true;
    }).toList();
  }

  List<Car> _sortResults(List<Car> cars, SortBy sortBy, SortOrder sortOrder) {
    cars.sort((a, b) {
      int comparison = 0;

      switch (sortBy) {
        case SortBy.brand:
          comparison = a.brand.compareTo(b.brand);
          break;
        case SortBy.model:
          comparison = a.model.compareTo(b.model);
          break;
        case SortBy.year:
          comparison = int.parse(a.year).compareTo(int.parse(b.year));
          break;
        case SortBy.price:
          final priceA =
              double.tryParse(a.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
          final priceB =
              double.tryParse(b.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
          comparison = priceA.compareTo(priceB);
          break;
        case SortBy.addedDate:
          comparison = a.addedDate.compareTo(b.addedDate);
          break;
        case SortBy.soldDate:
          if (a.soldDate == null && b.soldDate == null) {
            comparison = 0;
          } else if (a.soldDate == null) {
            comparison = 1;
          } else if (b.soldDate == null) {
            comparison = -1;
          } else {
            comparison = a.soldDate!.compareTo(b.soldDate!);
          }
          break;
      }

      return sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    return cars;
  }
}

class SearchOptions {
  final bool searchInBrand;
  final bool searchInModel;
  final bool searchInYear;
  final bool searchInFuelType;
  final bool searchInColor;
  final bool searchInTransmission;
  final bool searchInCustomer;
  final bool searchInDescription;

  final double? minPrice;
  final double? maxPrice;
  final int? minYear;
  final int? maxYear;
  final SoldStatus? soldStatus;
  final List<String> fuelTypes;
  final List<String> brands;

  final SortBy sortBy;
  final SortOrder sortOrder;
  const SearchOptions({
    this.searchInBrand = true,
    this.searchInModel = true,
    this.searchInYear = true,
    this.searchInFuelType = true,
    this.searchInColor = true,
    this.searchInTransmission = true,
    this.searchInCustomer = true,
    this.searchInDescription = true,
    this.minPrice,
    this.maxPrice,
    this.minYear,
    this.maxYear,
    this.soldStatus,
    this.fuelTypes = const [],
    this.brands = const [],
    this.sortBy = SortBy.addedDate,
    this.sortOrder = SortOrder.descending,
  });

  SearchOptions copyWith({
    bool? searchInBrand,
    bool? searchInModel,
    bool? searchInYear,
    bool? searchInFuelType,
    bool? searchInColor,
    bool? searchInTransmission,
    bool? searchInCustomer,
    bool? searchInDescription,
    double? minPrice,
    double? maxPrice,
    int? minYear,
    int? maxYear,
    SoldStatus? soldStatus,
    List<String>? fuelTypes,
    List<String>? brands,
    SortBy? sortBy,
    SortOrder? sortOrder,
  }) {
    return SearchOptions(
      searchInBrand: searchInBrand ?? this.searchInBrand,
      searchInModel: searchInModel ?? this.searchInModel,
      searchInYear: searchInYear ?? this.searchInYear,
      searchInFuelType: searchInFuelType ?? this.searchInFuelType,
      searchInColor: searchInColor ?? this.searchInColor,
      searchInTransmission: searchInTransmission ?? this.searchInTransmission,
      searchInCustomer: searchInCustomer ?? this.searchInCustomer,
      searchInDescription: searchInDescription ?? this.searchInDescription,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
      soldStatus: soldStatus ?? this.soldStatus,
      fuelTypes: fuelTypes ?? this.fuelTypes,
      brands: brands ?? this.brands,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'SearchOptions{sortBy: $sortBy, sortOrder: $sortOrder, soldStatus: $soldStatus}';
  }
}

enum SoldStatus { all, sold, available }

enum SortBy { brand, model, year, price, addedDate, soldDate }

enum SortOrder { ascending, descending }

class SearchStatistics {
  final bool isIndexed;
  final DateTime? lastIndexUpdate;
  final int totalCarsIndexed;
  final Map<String, int> indexSizes;

  const SearchStatistics({
    required this.isIndexed,
    required this.lastIndexUpdate,
    required this.totalCarsIndexed,
    required this.indexSizes,
  });
}
