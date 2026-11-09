import '../models/product.dart';
import '../models/product_query.dart';
import 'crud_repository.dart';

/// Хранилище товаров.
abstract interface class ProductRepository
    implements CrudRepository<Product, ProductQuery> {}
