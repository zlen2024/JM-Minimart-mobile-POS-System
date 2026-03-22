import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_local_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryLocalDataSource localDataSource;

  InventoryRepositoryImpl(this.localDataSource);

  @override
  Future<List<Category>> getCategories() async {
    return await localDataSource.getCategories();
  }

  @override
  Future<Category> addCategory(Category category) async {
    return await localDataSource.addCategory(category);
  }

  @override
  Future<int> updateCategory(Category category) async {
    return await localDataSource.updateCategory(category);
  }

  @override
  Future<int> deleteCategory(int id) async {
    return await localDataSource.deleteCategory(id);
  }

  @override
  Future<List<Product>> getProducts() async {
    return await localDataSource.getProducts();
  }

  @override
  Future<Product> addProduct(Product product) async {
    return await localDataSource.addProduct(product);
  }

  @override
  Future<int> updateProduct(Product product) async {
    return await localDataSource.updateProduct(product);
  }

  @override
  Future<int> deleteProduct(int id) async {
    return await localDataSource.deleteProduct(id);
  }
}
