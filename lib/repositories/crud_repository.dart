import '../models/entity.dart';
import '../models/page_result.dart';

abstract interface class CrudRepository<T extends Entity, Q> {
  /// Одна страница записей, подходящих под условия [query].
  Future<PageResult<T>> find(Q query);

  /// Запись по идентификатору, в том числе логически удалённая.
  /// `null` — записи нет совсем.
  Future<T?> findById(int id);

  Future<T> create(T item);

  Future<T> update(T item);

  /// Логическое удаление: проставляет `deletedAt`, запись пропадает из
  /// обычной выборки, но её можно восстановить.
  Future<void> softDelete(int id);

  /// Физическое удаление: запись стирается насовсем.
  Future<void> hardDelete(int id);

  /// Снимает пометку логического удаления.
  Future<void> restore(int id);

  /// Логически удаляет несколько записей. Возвращает, сколько записей
  /// действительно было удалено: уже удалённые и несуществующие не считаются.
  Future<int> deleteMany(List<int> ids);
}
