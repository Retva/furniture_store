import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router.dart';
import 'core/scroll_behavior.dart';
import 'repositories/category_repository.dart';
import 'repositories/in_memory_category_repository.dart';
import 'repositories/in_memory_manufacturer_repository.dart';
import 'repositories/in_memory_product_repository.dart';
import 'repositories/manufacturer_repository.dart';
import 'repositories/network_simulator.dart';
import 'repositories/product_repository.dart';
import 'state/manufacturer_list_notifier.dart';
import 'state/network_settings_notifier.dart';
import 'state/product_list_notifier.dart';
import 'state/reference_data_notifier.dart';

class FurnitureStoreApp extends StatefulWidget {
  const FurnitureStoreApp({super.key, this.network});

  /// Симулятор сети можно подменить снаружи.
  final NetworkSimulator? network;

  @override
  State<FurnitureStoreApp> createState() => _FurnitureStoreAppState();
}

class _FurnitureStoreAppState extends State<FurnitureStoreApp> {
  // Роутер создаётся один раз. Если создавать его в build, при каждой
  // перестройке приложение возвращалось бы на стартовый экран.
  late final GoRouter _router = createRouter();
  late final NetworkSimulator _network = widget.network ?? NetworkSimulator();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ProductRepository>(
          create: (_) => InMemoryProductRepository(network: _network),
        ),
        Provider<ManufacturerRepository>(
          create: (_) => InMemoryManufacturerRepository(network: _network),
        ),
        Provider<CategoryRepository>(
          create: (_) => InMemoryCategoryRepository(network: _network),
        ),

        // Состояние. ChangeNotifierProvider сам вызовет dispose().
        ChangeNotifierProvider(
          create: (context) =>
              ProductListNotifier(context.read<ProductRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ManufacturerListNotifier(context.read<ManufacturerRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ReferenceDataNotifier(
            context.read<CategoryRepository>(),
            context.read<ManufacturerRepository>(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => NetworkSettingsNotifier(_network),
        ),
      ],
      child: MaterialApp.router(
        title: 'МебельДом',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        routerConfig: _router,
        scrollBehavior: const AppScrollBehavior(),
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
