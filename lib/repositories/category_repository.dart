import '../models/product_category.dart';

/// Справочник категорий. В этой работе только читается.
abstract interface class CategoryRepository {
  Future<List<ProductCategory>> findAll();
}
