import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/database_helper.dart';
import '../../data/datasources/pos_local_datasource.dart';
import '../../data/repositories/pos_repository_impl.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/pos_repository.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final posLocalDataSourceProvider = Provider<PosLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return PosLocalDataSourceImpl(dbHelper);
});

final posRepositoryProvider = Provider<PosRepository>((ref) {
  final localDataSource = ref.watch(posLocalDataSourceProvider);
  return PosRepositoryImpl(localDataSource);
});

final salesProvider = AsyncNotifierProvider<SalesNotifier, List<Sale>>(() {
  return SalesNotifier();
});

class SalesNotifier extends AsyncNotifier<List<Sale>> {
  @override
  Future<List<Sale>> build() async {
    return ref.watch(posRepositoryProvider).getSales();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(posRepositoryProvider).getSales();
    });
  }
}
