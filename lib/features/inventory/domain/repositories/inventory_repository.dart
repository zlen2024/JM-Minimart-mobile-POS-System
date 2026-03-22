import '../entities/category.dart';
import '../entities/product.dart';

abstract class InventoryRepository {
  Future<List<Category>> getCategories();
  Future<Category> addCategory(Category category);
  Future<int> updateCategory(Category category);
  Future<int> deleteCategory(int id);

  Future<List<Product>> getProducts();
  Future<Product> addProduct(Product product);
  Future<int> updateProduct(Product product);
  Future<int> deleteProduct(int id);
}
