import '../models/entity.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import 'crud_repository.dart';
import 'network_simulator.dart';
import 'repository_exception.dart';

/// Общая часть хранилищ в памяти: страницы, сортировка, удаление и восстановление.
abstract class InMemoryCrudRepository<T extends Entity, Q extends ListQuery>
    implements CrudRepository<T, Q> {
  InMemoryCrudRepository(List<T> seed, {NetworkSimulator? network})
    : records = [...seed],
      _nextId = seed.fold<int>(0, (max, x) => x.id > max ? x.id : max) + 1,
      network = network ?? NetworkSimulator();

  /// Все записи, включая логически удалённые. Открыто только наследникам:
  /// снаружи к данным обращаются через методы интерфейса.
  final List<T> records;

  final NetworkSimulator network;

  int _nextId;

  String get entityName;

  bool matches(T item, Q query);

  int compareBy(T a, T b, String field);

  T withDeletedAt(T item, DateTime? deletedAt);

  T withId(T item, int id);

  void validate(T item) {}

  @override
  Future<PageResult<T>> find(Q query) async {
    await network.roundTrip();

    final rows = records
        .where((item) => query.includeDeleted || !item.isDeleted)
        .where((item) => matches(item, query))
        .toList();

    rows.sort((a, b) {
      var result = compareBy(a, b, query.sortField);
      if (result == 0) result = a.id.compareTo(b.id);
      return query.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (query.page - 1) * query.size;
    // num.clamp возвращает num, а sublist ждёт int — границу считаем явно.
    final to = (from + query.size) > total ? total : (from + query.size);
    final items = from >= total ? <T>[] : rows.sublist(from, to);

    return PageResult<T>(
      items: List.unmodifiable(items),
      page: query.page,
      size: query.size,
      total: total,
    );
  }

  @override
  Future<T?> findById(int id) async {
    await network.roundTrip();
    return records.where((item) => item.id == id).firstOrNull;
  }

  @override
  Future<T> create(T item) async {
    await network.roundTrip();
    final created = withId(item, _nextId++);
    validate(created);
    records.add(created);
    return created;
  }

  @override
  Future<T> update(T item) async {
    await network.roundTrip();
    final i = _indexOf(item.id);
    validate(item);
    records[i] = item;
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    await network.roundTrip();
    final i = _indexOf(id);
    records[i] = withDeletedAt(records[i], DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await network.roundTrip();
    _indexOf(id); // бросит понятную ошибку, если записи уже нет
    records.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> restore(int id) async {
    await network.roundTrip();
    final i = _indexOf(id);
    records[i] = withDeletedAt(records[i], null);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await network.roundTrip();
    var count = 0;
    final now = DateTime.now();
    for (final id in ids) {
      final i = records.indexWhere((item) => item.id == id && !item.isDeleted);
      if (i != -1) {
        records[i] = withDeletedAt(records[i], now);
        count++;
      }
    }
    return count;
  }

  int _indexOf(int id) {
    final i = records.indexWhere((item) => item.id == id);
    if (i == -1) {
      throw RepositoryException('$entityName с номером $id не найден.');
    }
    return i;
  }
}

int compareText(String a, String b) =>
    a.toLowerCase().compareTo(b.toLowerCase());
