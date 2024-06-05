import 'package:get_it/get_it.dart';
import 'package:kopma/data/datasource/local/local_database.dart';
import '../data/datasource/network/firebase_transaction_datasource.dart';
import '../data/datasource/shared_preferences_service.dart';
import '../data/transaction_repository.dart';

final serviceLocator = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Register services
  final sharedPreferencesService = await SharedPreferencesService.getInstance();
  serviceLocator
    ..registerSingleton(sharedPreferencesService)
    ..registerLazySingleton<LocalDatabase>(LocalDatabase.new);

}