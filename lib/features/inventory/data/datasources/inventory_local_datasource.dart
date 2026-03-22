import 'package:sqflite/sqflite.dart';
import '../../../../core/db/database_helper.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

abstract class InventoryLocalDataSource {
  Future<List<Category>> getCategories();
  Future<Category> addCategory(Category category);
  Future<int> updateCategory(Category category);
  Future<int> deleteCategory(int id);

  Future<List<Product>> getProducts();
  Future<Product> addProduct(Product product);
  Future<int> updateProduct(Product product);
  Future<int> deleteProduct(int id);
}

class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  final DatabaseHelper dbHelper;

  InventoryLocalDataSourceImpl(this.dbHelper);

  @override
  Future<List<Category>> getCategories() async {
    final db = await dbHelper.database;
    final maps = await db.query('categories');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  @override
  Future<Category> addCategory(Category category) async {
    final db = await dbHelper.database;
    final id = await db.insert('categories', category.toMap());
    return category.copyWith(id: id);
  }

  @override
  Future<int> updateCategory(Category category) async {
    final db = await dbHelper.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<int> deleteCategory(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Product>> getProducts() async {
    final db = await dbHelper.database;
    final maps = await db.query('products');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  @override
  Future<Product> addProduct(Product product) async {
    final db = await dbHelper.database;
    final id = await db.insert('products', product.toMap());
    return product.copyWith(id: id);
  }

  @override
  Future<int> updateProduct(Product product) async {
    final db = await dbHelper.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  @override
  Future<int> deleteProduct(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
