import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../../features/pos/domain/entities/sale.dart';
import '../../../../features/inventory/domain/entities/product.dart';

class ReceiptGenerator {
  static Future<void> generateAndPrintReceipt(Sale sale, List<SaleItem> saleItems, List<Product> products) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'JM Mini Mart',
                  style: pw.TextStyle(font: fontBold, fontSize: 24),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  '123 Retail Ave, Commerce City',
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Receipt #: ${sale.id ?? "N/A"}', style: pw.TextStyle(font: font, fontSize: 12)),
              pw.Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.createdAt ?? DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 12)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              // Items header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item', style: pw.TextStyle(font: fontBold))),
                  pw.Expanded(flex: 1, child: pw.Text('Qty', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 2, child: pw.Text('Price', style: pw.TextStyle(font: fontBold), textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.SizedBox(height: 5),
              // Items list
              ...saleItems.map((item) {
                final product = products.firstWhere((p) => p.id == item.productId, orElse: () => Product(name: 'Unknown', sku: '', categoryId: 0, price: 0, stockQuantity: 0, ));
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(product.name, style: pw.TextStyle(font: font, fontSize: 10))),
                      pw.Expanded(flex: 1, child: pw.Text(item.quantity.toString(), style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 2, child: pw.Text('\$${(item.quantity * item.unitPrice).toStringAsFixed(2)}', style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                );
              }).toList(),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: pw.TextStyle(font: font)),
                  pw.Text('\$${(sale.totalAmount / 1.08).toStringAsFixed(2)}', style: pw.TextStyle(font: font)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tax (8%)', style: pw.TextStyle(font: font)),
                  pw.Text('\$${(sale.totalAmount - (sale.totalAmount / 1.08)).toStringAsFixed(2)}', style: pw.TextStyle(font: font)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(font: fontBold, fontSize: 16)),
                  pw.Text('\$${sale.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('Thank you for shopping with us!', style: pw.TextStyle(font: font, fontStyle: pw.FontStyle.italic)),
              ),
              pw.SizedBox(height: 30),
              // Optional: Add a barcode at the bottom
              if (sale.id != null)
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: sale.id.toString(),
                    width: 150,
                    height: 50,
                  ),
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${sale.id}',
    );
  }
}
