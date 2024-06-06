import 'package:get_it/get_it.dart';
import 'package:kopma/data/datasource/local/local_database.dart';
import 'package:kopma/data/datasource/local/local_cart_datasource.dart';
import 'package:kopma/data/datasource/network/firebase_item_datasource.dart';
import 'package:kopma/data/datasource/shared_preferences_service.dart';

import '../data/item_repository.dart';
import '../data/item_repository_impl.dart'; // Import the SharedPreferencesService

final serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Register services

  // Register SharedPreferencesService
  serviceLocator.registerSingletonAsync<SharedPreferencesService>(() async {
    return SharedPreferencesService.getInstance();
  });

  // Register LocalDatabase
  serviceLocator.registerLazySingleton<LocalDatabase>(() => LocalDatabase());

  // Register LocalCartDataSource
  serviceLocator.registerLazySingleton<LocalCartDataSource>(() => LocalCartDataSource());

  // Register FirebaseItemDataSource
  serviceLocator.registerLazySingleton<FirebaseItemDataSource>(() => FirebaseItemDataSource());

  // Register repositories
  serviceLocator.registerLazySingleton<ItemRepository>(() => ItemRepositoryImpl(
    serviceLocator<FirebaseItemDataSource>(),
    serviceLocator<LocalCartDataSource>(),
  ));
}
