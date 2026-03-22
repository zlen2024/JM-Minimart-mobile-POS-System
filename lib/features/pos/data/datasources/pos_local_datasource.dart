import 'package:sqflite/sqflite.dart';
import '../../../../core/db/database_helper.dart';
import '../../domain/entities/sale.dart';

abstract class PosLocalDataSource {
  Future<Sale> createSale(Sale sale, List<SaleItem> items);
  Future<List<Sale>> getSales();
  Future<List<SaleItem>> getSaleItems(int saleId);
}

class PosLocalDataSourceImpl implements PosLocalDataSource {
  final DatabaseHelper dbHelper;

  PosLocalDataSourceImpl(this.dbHelper);

  @override
  Future<Sale> createSale(Sale sale, List<SaleItem> items) async {
    final db = await dbHelper.database;

    return await db.transaction((txn) async {
      final saleId = await txn.insert('sales', sale.toMap());

      for (final item in items) {
        final itemToInsert = item.copyWith(saleId: saleId);
        await txn.insert('sale_items', itemToInsert.toMap());

        // Update stock quantity
        await txn.rawUpdate(
          'UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?',
          [item.quantity, item.productId]
        );
      }

      return sale.copyWith(id: saleId);
    });
  }

  @override
  Future<List<Sale>> getSales() async {
    final db = await dbHelper.database;
    final maps = await db.query('sales', orderBy: 'created_at DESC');
    return maps.map((map) => Sale.fromMap(map)).toList();
  }

  @override
  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final db = await dbHelper.database;
    final maps = await db.query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
    return maps.map((map) => SaleItem.fromMap(map)).toList();
  }
}
