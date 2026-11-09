import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import 'in_memory_crud_repository.dart';
import 'manufacturer_repository.dart';
import 'seed_data.dart';

/// Производители в памяти. Начальный набор — [seedManufacturers].
class InMemoryManufacturerRepository
    extends InMemoryCrudRepository<Manufacturer, ManufacturerQuery>
    implements ManufacturerRepository {
  InMemoryManufacturerRepository({List<Manufacturer>? seed, super.network})
    : super(seed ?? seedManufacturers);

  @override
  String get entityName => 'Производитель';

  @override
  bool matches(Manufacturer m, ManufacturerQuery q) {
    // Поиск — по названию и стране: «ита» найдёт итальянские фабрики.
    final needle = q.search.trim().toLowerCase();
    if (needle.isNotEmpty &&
        !m.name.toLowerCase().contains(needle) &&
        !m.country.toLowerCase().contains(needle)) {
      return false;
    }
    if (q.country != null && m.country != q.country) return false;
    return true;
  }

  @override
  int compareBy(Manufacturer a, Manufacturer b, String field) {
    return switch (field) {
      'country' => compareText(a.country, b.country),
      'foundedYear' => a.foundedYear.compareTo(b.foundedYear),
      _ => compareText(a.name, b.name),
    };
  }

  @override
  Manufacturer withDeletedAt(Manufacturer item, DateTime? deletedAt) =>
      deletedAt == null
      ? item.copyWith(clearDeletedAt: true)
      : item.copyWith(deletedAt: deletedAt);

  @override
  Manufacturer withId(Manufacturer item, int id) => item.withId(id);

  @override
  Future<List<Manufacturer>> findAllForLookup() async {
    await network.roundTrip();
    return List.unmodifiable(
      <Manufacturer>[...records]..sort((a, b) => compareText(a.name, b.name)),
    );
  }

  @override
  Future<List<String>> countries() async {
    await network.roundTrip();
    final set = {
      for (final m in records)
        if (!m.isDeleted) m.country,
    };
    return set.toList()..sort(compareText);
  }
}
