import '../../domain/entities/report.dart';
import '../../domain/repositories/reporting_repository.dart';
import '../datasources/reporting_local_datasource.dart';

class ReportingRepositoryImpl implements ReportingRepository {
  final ReportingLocalDataSource localDataSource;

  ReportingRepositoryImpl(this.localDataSource);

  @override
  Future<SalesReport> getSalesReport(DateTime startDate, DateTime endDate) async {
    return await localDataSource.getSalesReport(startDate, endDate);
  }

  @override
  Future<List<DailySalesData>> getDailySalesData(DateTime startDate, DateTime endDate) async {
    return await localDataSource.getDailySalesData(startDate, endDate);
  }
}
