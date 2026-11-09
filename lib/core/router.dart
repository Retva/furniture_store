import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../repositories/manufacturer_repository.dart';
import '../repositories/product_repository.dart';
import '../screens/home_screen.dart';
import '../screens/manufacturer_detail_screen.dart';
import '../screens/manufacturer_list_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_list_screen.dart';
import '../state/entity_detail_notifier.dart';
import '../widgets/app_shell.dart';

/// Маршруты приложения.
/// Условия отбора списков живут в параметрах адреса. Маршрут разбирает их в
/// объект запроса и передаёт экрану — экран своей копии фильтров не хранит,
/// поэтому адрес и то, что на экране, не могут разойтись.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/products',
            builder: (context, state) => ProductListScreen(
              query: ProductQuery.fromParameters(state.uri.queryParameters),
            ),
          ),
          GoRoute(
            path: '/products/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) {
                return NotFoundScreen(location: state.uri.toString());
              }
              return ChangeNotifierProvider(
                key: ValueKey('product-$id'),
                create: (context) => EntityDetailNotifier<Product>(
                  context.read<ProductRepository>(),
                  id,
                )..load(),
                child: const ProductDetailScreen(),
              );
            },
          ),
          GoRoute(
            path: '/manufacturers',
            builder: (context, state) => ManufacturerListScreen(
              query: ManufacturerQuery.fromParameters(
                state.uri.queryParameters,
              ),
            ),
          ),
          GoRoute(
            path: '/manufacturers/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) {
                return NotFoundScreen(location: state.uri.toString());
              }
              return ChangeNotifierProvider(
                key: ValueKey('manufacturer-$id'),
                create: (context) => EntityDetailNotifier<Manufacturer>(
                  context.read<ManufacturerRepository>(),
                  id,
                )..load(),
                child: const ManufacturerDetailScreen(),
              );
            },
          ),
        ],
      ),
    ],
  );
}
