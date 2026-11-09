import 'package:flutter/foundation.dart';

import '../models/entity.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../repositories/crud_repository.dart';
import '../repositories/repository_exception.dart';
import 'list_state.dart';

/// Состояние экрана списка: условия отбора, текущая страница, выделение.
class EntityListNotifier<T extends Entity, Q extends ListQuery>
    extends ChangeNotifier {
  EntityListNotifier(this._repository, Q initialQuery) : _query = initialQuery;

  final CrudRepository<T, Q> _repository;

  Q _query;
  ListState<T> _state = ListLoading<T>();
  final Set<int> _selected = {};

  int _requestId = 0;
  bool _disposed = false;

  Q get query => _query;
  ListState<T> get state => _state;

  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  bool isSelected(int id) => _selected.contains(id);

  /// Последняя полученная страница — и во время загрузки следующей тоже.
  PageResult<T>? get currentResult => switch (_state) {
    ListLoaded(:final result) => result,
    ListLoading(:final previous) => previous,
    ListFailed() => null,
  };

  /// Загружает страницу по текущим условиям.
  Future<void> load() async {
    final requestId = ++_requestId;
    _state = ListLoading<T>(previous: currentResult);
    _notify();

    try {
      final result = await _repository.find(_query);
      if (requestId != _requestId) return;
      _state = ListLoaded<T>(result);
    } catch (error) {
      if (requestId != _requestId) return;
      _state = ListFailed<T>(_describe(error));
    }
    _notify();
  }

  Future<void> applyQuery(Q next, {bool force = false}) async {
    final unchanged = next == _query && _state is ListLoaded<T>;
    if (unchanged && !force) return;

    // Выделение теряет смысл при смене условий: отмеченные записи могли
    // уйти с экрана, и «удалить выбранные» удалило бы невидимое.
    if (next != _query) _selected.clear();
    _query = next;
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    _notify();
  }

  /// Отметить или снять все записи из [ids] — флажок в заголовке таблицы.
  void setSelection(Iterable<int> ids, bool selected) {
    selected ? _selected.addAll(ids) : _selected.removeAll(ids);
    _notify();
  }

  void clearSelection() {
    _selected.clear();
    _notify();
  }

  /// Логически удаляет выбранные записи. Возвращает, сколько удалено.
  Future<int> deleteSelected() async {
    final count = await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
    return count;
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }

  String _describe(Object error) => error is RepositoryException
      ? error.message
      : 'Не удалось загрузить список: $error';

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
