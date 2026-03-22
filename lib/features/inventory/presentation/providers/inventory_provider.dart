import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/database_helper.dart';
import '../../data/datasources/inventory_local_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/inventory_repository.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final inventoryLocalDataSourceProvider = Provider<InventoryLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return InventoryLocalDataSourceImpl(dbHelper);
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final localDataSource = ref.watch(inventoryLocalDataSourceProvider);
  return InventoryRepositoryImpl(localDataSource);
});

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(() {
  return CategoriesNotifier();
});

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return ref.watch(inventoryRepositoryProvider).getCategories();
  }

  Future<void> addCategory(Category category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).addCategory(category);
      return ref.read(inventoryRepositoryProvider).getCategories();
    });
  }

  Future<void> updateCategory(Category category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).updateCategory(category);
      return ref.read(inventoryRepositoryProvider).getCategories();
    });
  }

  Future<void> deleteCategory(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).deleteCategory(id);
      return ref.read(inventoryRepositoryProvider).getCategories();
    });
  }
}

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(() {
  return ProductsNotifier();
});

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return ref.watch(inventoryRepositoryProvider).getProducts();
  }

  Future<void> addProduct(Product product) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).addProduct(product);
      return ref.read(inventoryRepositoryProvider).getProducts();
    });
  }

  Future<void> updateProduct(Product product) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).updateProduct(product);
      return ref.read(inventoryRepositoryProvider).getProducts();
    });
  }

  Future<void> deleteProduct(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(inventoryRepositoryProvider).deleteProduct(id);
      return ref.read(inventoryRepositoryProvider).getProducts();
    });
  }
}
