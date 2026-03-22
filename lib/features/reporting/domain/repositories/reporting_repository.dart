import '../entities/report.dart';

abstract class ReportingRepository {
  Future<SalesReport> getSalesReport(DateTime startDate, DateTime endDate);
  Future<List<DailySalesData>> getDailySalesData(DateTime startDate, DateTime endDate);
}
