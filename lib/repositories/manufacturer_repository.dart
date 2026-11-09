import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import 'crud_repository.dart';

/// Хранилище производителей.
abstract interface class ManufacturerRepository
    implements CrudRepository<Manufacturer, ManufacturerQuery> {
  Future<List<Manufacturer>> findAllForLookup();

  Future<List<String>> countries();
}
