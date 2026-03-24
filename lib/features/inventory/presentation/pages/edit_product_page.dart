import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../providers/inventory_provider.dart';
import '../../../../core/widgets/barcode_scanner_page.dart';

class EditProductPage extends ConsumerStatefulWidget {
  final Product product;

  const EditProductPage({Key? key, required this.product}) : super(key: key);

  @override
  ConsumerState<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends ConsumerState<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _barcodeController;
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _skuController = TextEditingController(text: widget.product.sku);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _barcodeController = TextEditingController(text: widget.product.barcode ?? '');
    _stockController = TextEditingController(text: widget.product.stockQuantity.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final sku = _skuController.text;
      final price = double.parse(_priceController.text);
      final barcode = _barcodeController.text;
      final stock = int.parse(_stockController.text);

      final updatedProduct = widget.product.copyWith(
        name: name,
        sku: sku,
        price: price,
        barcode: barcode.isNotEmpty ? barcode : null,
        stockQuantity: stock,
        lastUpdated: DateTime.now(),
      );

      try {
        await ref.read(productsProvider.notifier).updateProduct(updatedProduct);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update product: $e')),
          );
        }
      }
    }
  }

  void _scanBarcode() async {
    final scannedBarcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );
    if (scannedBarcode != null) {
      setState(() {
        _barcodeController.text = scannedBarcode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Enter an SKU' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter a price';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Barcode (Optional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanBarcode,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter stock quantity';
                  if (int.tryParse(value) == null) return 'Enter a valid integer';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Update Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
