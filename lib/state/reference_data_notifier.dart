import 'package:flutter/foundation.dart';

import '../models/product_category.dart';
import '../models/manufacturer.dart';
import '../repositories/category_repository.dart';
import '../repositories/manufacturer_repository.dart';

enum ReferenceStatus { loading, ready, failed }

/// Справочники для подписей и выпадающих списков: категории, производители, страны.
class ReferenceDataNotifier extends ChangeNotifier {
  ReferenceDataNotifier(this._categories, this._manufacturers);

  final CategoryRepository _categories;
  final ManufacturerRepository _manufacturers;

  ReferenceStatus _status = ReferenceStatus.loading;
  List<ProductCategory> _categoryList = const [];
  List<Manufacturer> _manufacturerList = const [];
  List<String> _countries = const [];
  bool _disposed = false;

  ReferenceStatus get status => _status;
  List<ProductCategory> get categories => _categoryList;

  List<Manufacturer> get manufacturers => _manufacturerList;

  /// Только действующие — для выбора в фильтре.
  List<Manufacturer> get activeManufacturers =>
      _manufacturerList.where((m) => !m.isDeleted).toList();

  List<String> get countries => _countries;

  Future<void> load() async {
    if (_categoryList.isEmpty) {
      _status = ReferenceStatus.loading;
      if (!_disposed) notifyListeners();
    }
    try {
      final results = await Future.wait([
        _categories.findAll(),
        _manufacturers.findAllForLookup(),
        _manufacturers.countries(),
      ]);
      _categoryList = results[0] as List<ProductCategory>;
      _manufacturerList = results[1] as List<Manufacturer>;
      _countries = results[2] as List<String>;
      _status = ReferenceStatus.ready;
    } catch (_) {
      _status = ReferenceStatus.failed;
    }
    if (!_disposed) notifyListeners();
  }

  ProductCategory? categoryOf(int id) =>
      _categoryList.where((c) => c.id == id).firstOrNull;

  Manufacturer? manufacturerOf(int id) =>
      _manufacturerList.where((m) => m.id == id).firstOrNull;

  String categoryName(int id) => categoryOf(id)?.name ?? '—';

  String manufacturerName(int id) => manufacturerOf(id)?.name ?? '—';

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
