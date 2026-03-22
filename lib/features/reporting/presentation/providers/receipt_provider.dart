import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../../core/db/database_helper.dart';
import '../../../pos/domain/entities/sale.dart';
import '../../../inventory/data/datasources/inventory_local_datasource.dart';

final receiptGeneratorProvider = Provider<ReceiptGenerator>((ref) {
  final dbHelper = ref.read(databaseHelperProvider);
  final inventoryLocal = InventoryLocalDataSourceImpl(dbHelper);
  return ReceiptGenerator(inventoryLocal);
});

class ReceiptGenerator {
  final InventoryLocalDataSourceImpl inventoryDataSource;

  ReceiptGenerator(this.inventoryDataSource);

  Future<pw.Document> generateReceipt(Sale sale, List<SaleItem> items) async {
    final pdf = pw.Document();

    // Fetch product names for items
    final products = await inventoryDataSource.getProducts();
    final productMap = {for (var p in products) p.id: p};

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('JM Mini Mart', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Receipt #: ${sale.id ?? "N/A"}'),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.createdAt ?? DateTime.now())}'),
              pw.Text('Payment: ${sale.paymentMethod ?? "Cash"}'),
              pw.Divider(),

              // Items
              ...items.map((item) {
                final product = productMap[item.productId];
                final productName = product?.name ?? 'Unknown Product';
                final total = item.quantity * item.unitPrice;

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text('${item.quantity}x $productName'),
                      ),
                      pw.Text('\$${total.toStringAsFixed(2)}'),
                    ],
                  ),
                );
              }).toList(),

              pw.Divider(),
              if ((sale.discountAmount ?? 0) > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount:'),
                    pw.Text('-\$${sale.discountAmount!.toStringAsFixed(2)}'),
                  ],
                ),
              ],
              if ((sale.taxAmount ?? 0) > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Tax:'),
                    pw.Text('\$${sale.taxAmount!.toStringAsFixed(2)}'),
                  ],
                ),
              ],
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${sale.totalAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('Thank you for your purchase!', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
