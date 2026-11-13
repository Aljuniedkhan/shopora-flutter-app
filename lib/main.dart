import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'data/datasource/product_local_datasource.dart';
import 'data/datasource/product_remote_datasource.dart';
import 'data/repository/product_repository.dart';
import 'presentation/screens/splash_screen.dart';
import 'providers/product_provider.dart';
import 'providers/theme_provider.dart';
import 'services/connectivity_service.dart';

Future<void> main() async {
  // Needed because we use plugins (Hive) before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  final localDataSource = ProductLocalDataSource();
  await localDataSource.init();

  runApp(
    // Dependency injection: objects are created once here and every
    // screen below can read them with context.read / context.watch.
    MultiProvider(
      providers: [
        Provider<ProductRepository>(
          create: (_) =>
              ProductRepository(ProductRemoteDataSource(), localDataSource),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(localDataSource),
        ),
        ChangeNotifierProvider<ProductProvider>(
          // lazy: false starts loading products while the splash is shown.
          lazy: false,
          create: (context) => ProductProvider(
            context.read<ProductRepository>(),
            ConnectivityService(),
          )..init(),
        ),
      ],
      child: const ShoporaApp(),
    ),
  );
}

class ShoporaApp extends StatelessWidget {
  const ShoporaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
