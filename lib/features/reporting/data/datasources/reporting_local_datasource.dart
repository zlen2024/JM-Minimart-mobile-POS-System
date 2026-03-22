import 'package:sqflite/sqflite.dart';
import '../../../../core/db/database_helper.dart';
import '../../domain/entities/report.dart';

abstract class ReportingLocalDataSource {
  Future<SalesReport> getSalesReport(DateTime startDate, DateTime endDate);
  Future<List<DailySalesData>> getDailySalesData(DateTime startDate, DateTime endDate);
}

class ReportingLocalDataSourceImpl implements ReportingLocalDataSource {
  final DatabaseHelper dbHelper;

  ReportingLocalDataSourceImpl(this.dbHelper);

  @override
  Future<SalesReport> getSalesReport(DateTime startDate, DateTime endDate) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
      SELECT
        COUNT(DISTINCT s.id) as total_transactions,
        SUM(s.total_amount) as total_revenue,
        SUM(si.quantity * p.cost_price) as total_cost
      FROM sales s
      LEFT JOIN sale_items si ON s.id = si.sale_id
      LEFT JOIN products p ON si.product_id = p.id
      WHERE s.created_at >= ? AND s.created_at <= ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    if (result.isEmpty || result.first['total_transactions'] == 0) {
      return SalesReport(
        startDate: startDate,
        endDate: endDate,
        totalRevenue: 0.0,
        totalCost: 0.0,
        totalTransactions: 0,
      );
    }

    return SalesReport(
      startDate: startDate,
      endDate: endDate,
      totalRevenue: (result.first['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalCost: (result.first['total_cost'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: (result.first['total_transactions'] as int?) ?? 0,
    );
  }

  @override
  Future<List<DailySalesData>> getDailySalesData(DateTime startDate, DateTime endDate) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery('''
      SELECT
        DATE(created_at) as sale_date,
        SUM(total_amount) as daily_total
      FROM sales
      WHERE created_at >= ? AND created_at <= ?
      GROUP BY DATE(created_at)
      ORDER BY sale_date
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return result.map((row) {
      return DailySalesData(
        DateTime.parse(row['sale_date'] as String),
        (row['daily_total'] as num).toDouble(),
      );
    }).toList();
  }
}
