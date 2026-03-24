import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../providers/inventory_provider.dart';
import '../../../../core/widgets/barcode_scanner_page.dart';

class AddProductPage extends ConsumerStatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends ConsumerState<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _stockController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final sku = _skuController.text;
      final price = double.parse(_priceController.text);
      final barcode = _barcodeController.text;
      final stock = int.parse(_stockController.text);

      final newProduct = Product(
        name: name,
        sku: sku,
        categoryId: 1, // Defaulting category to 1 for simplicity in this demo
        price: price,
        barcode: barcode.isNotEmpty ? barcode : null,
        stockQuantity: stock,
      );

      try {
        await ref.read(productsProvider.notifier).addProduct(newProduct);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add product: $e')),
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
        title: const Text('Add Product'),
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
                decoration: const InputDecoration(labelText: 'Initial Stock Quantity', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter stock quantity';
                  if (int.tryParse(value) == null) return 'Enter a valid integer';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
