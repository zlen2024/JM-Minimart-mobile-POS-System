import '../entities/sale.dart';

abstract class PosRepository {
  Future<Sale> createSale(Sale sale, List<SaleItem> items);
  Future<List<Sale>> getSales();
  Future<List<SaleItem>> getSaleItems(int saleId);
}
