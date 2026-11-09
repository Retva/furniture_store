/// Ошибка хранилища данных с текстом, который можно показать человеку.
class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
