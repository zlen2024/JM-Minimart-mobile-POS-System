import '../../domain/entities/sale.dart';
import '../../domain/repositories/pos_repository.dart';
import '../datasources/pos_local_datasource.dart';

class PosRepositoryImpl implements PosRepository {
  final PosLocalDataSource localDataSource;

  PosRepositoryImpl(this.localDataSource);

  @override
  Future<Sale> createSale(Sale sale, List<SaleItem> items) async {
    return await localDataSource.createSale(sale, items);
  }

  @override
  Future<List<Sale>> getSales() async {
    return await localDataSource.getSales();
  }

  @override
  Future<List<SaleItem>> getSaleItems(int saleId) async {
    return await localDataSource.getSaleItems(saleId);
  }
}
