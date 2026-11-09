import '../models/product_category.dart';
import 'category_repository.dart';
import 'network_simulator.dart';
import 'seed_data.dart';

class InMemoryCategoryRepository implements CategoryRepository {
  InMemoryCategoryRepository({NetworkSimulator? network})
    : _network = network ?? NetworkSimulator();

  final NetworkSimulator _network;

  @override
  Future<List<ProductCategory>> findAll() async {
    await _network.roundTrip();
    return List.unmodifiable(seedCategories);
  }
}
