import '../models/product.dart';
import '../models/product_query.dart';
import 'in_memory_crud_repository.dart';
import 'product_repository.dart';
import 'repository_exception.dart';
import 'seed_data.dart';

/// Товары в памяти. Начальный набор — [seedProducts].
class InMemoryProductRepository
    extends InMemoryCrudRepository<Product, ProductQuery>
    implements ProductRepository {
  InMemoryProductRepository({List<Product>? seed, super.network})
    : super(seed ?? seedProducts);

  @override
  String get entityName => 'Товар';

  @override
  bool matches(Product p, ProductQuery q) {
    // Поиск — по названию и артикулу, без учёта регистра.
    final needle = q.search.trim().toLowerCase();
    if (needle.isNotEmpty &&
        !p.name.toLowerCase().contains(needle) &&
        !p.sku.toLowerCase().contains(needle)) {
      return false;
    }
    // Фильтры складываются через «и»: товар должен подойти под все сразу.
    if (q.categoryId != null && p.categoryId != q.categoryId) return false;
    if (q.manufacturerId != null && p.manufacturerId != q.manufacturerId) {
      return false;
    }
    if (q.priceFrom != null && p.price < q.priceFrom!) return false;
    if (q.priceTo != null && p.price > q.priceTo!) return false;
    return true;
  }

  @override
  int compareBy(Product a, Product b, String field) {
    return switch (field) {
      'sku' => compareText(a.sku, b.sku),
      'price' => a.price.compareTo(b.price),
      'stock' => a.stock.compareTo(b.stock),
      _ => compareText(a.name, b.name),
    };
  }

  @override
  Product withDeletedAt(Product item, DateTime? deletedAt) => deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);

  @override
  Product withId(Product item, int id) => item.withId(id);

  @override
  void validate(Product item) {
    final sku = item.sku.trim().toLowerCase();
    final taken = records.any(
      (other) => other.id != item.id && other.sku.toLowerCase() == sku,
    );
    if (taken) {
      throw RepositoryException(
        'Артикул ${item.sku} уже занят другим товаром.',
      );
    }
  }
}
