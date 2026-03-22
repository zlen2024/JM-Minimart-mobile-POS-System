import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/database_helper.dart';
import '../../data/datasources/reporting_local_datasource.dart';
import '../../data/repositories/reporting_repository_impl.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/reporting_repository.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final reportingLocalDataSourceProvider = Provider<ReportingLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return ReportingLocalDataSourceImpl(dbHelper);
});

final reportingRepositoryProvider = Provider<ReportingRepository>((ref) {
  final localDataSource = ref.watch(reportingLocalDataSourceProvider);
  return ReportingRepositoryImpl(localDataSource);
});

class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({required this.startDate, required this.endDate});
}

final dateRangeProvider = StateProvider<DateRange>((ref) {
  final now = DateTime.now();
  return DateRange(
    startDate: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7)),
    endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
  );
});

final salesReportProvider = FutureProvider<SalesReport>((ref) async {
  final dateRange = ref.watch(dateRangeProvider);
  final repo = ref.watch(reportingRepositoryProvider);
  return await repo.getSalesReport(dateRange.startDate, dateRange.endDate);
});

final dailySalesDataProvider = FutureProvider<List<DailySalesData>>((ref) async {
  final dateRange = ref.watch(dateRangeProvider);
  final repo = ref.watch(reportingRepositoryProvider);
  return await repo.getDailySalesData(dateRange.startDate, dateRange.endDate);
});
