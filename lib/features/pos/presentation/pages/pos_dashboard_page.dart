import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/cart_provider.dart';
import '../providers/pos_provider.dart';
import '../../domain/entities/sale.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import '../../../inventory/domain/entities/product.dart';
import '../../../reporting/presentation/utils/receipt_generator.dart';

class PosDashboardPage extends ConsumerStatefulWidget {
  const PosDashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PosDashboardPage> createState() => _PosDashboardPageState();
}

class _PosDashboardPageState extends ConsumerState<PosDashboardPage> {
  final Color _primaryColor = const Color(0xFF1A237E); // Deep Indigo
  final Color _surfaceColor = const Color(0xFFF8F9FA); // slate-50
  final Color _surfaceContainerLow = const Color(0xFFF3F4F5); // slightly darker background shift
  final Color _indigoLight = const Color(0xFFE8EAF6); // indigo-50

  final TextEditingController _searchController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  DateTime? _lastScanTime;

  @override
  void dispose() {
    _searchController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcode(String barcodeString) {
      // Throttle scans to once every 2 seconds
      if (_lastScanTime != null && DateTime.now().difference(_lastScanTime!) < const Duration(seconds: 2)) {
          return;
      }
      _lastScanTime = DateTime.now();

      final products = ref.read(productsProvider).value ?? [];
      final match = products.where((p) => p.barcode == barcodeString || p.sku == barcodeString).firstOrNull;

      if (match != null) {
          ref.read(cartProvider.notifier).addProduct(match);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${match.name}'), duration: const Duration(seconds: 1)));
      } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product with barcode $barcodeString not found.'), duration: const Duration(seconds: 1)));
      }
  }

  void _checkout() async {
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    // 1. Create Sale
    final sale = Sale(
      totalAmount: cartState.total,
      paymentMethod: 'Cash', // Defaulting for demo
      createdAt: DateTime.now(),
    );

    // 2. Create Sale Items
    final saleItems = cartState.items.map((item) => SaleItem(
      saleId: 0, // Assigned by DB
      productId: item.product.id!,
      quantity: item.quantity,
      unitPrice: item.product.price,
    )).toList();

    try {
      // 3. Save to DB
      final savedSale = await ref.read(posRepositoryProvider).createSale(sale, saleItems);

      // Update inventory (Simplified for demo - ideally done in a transaction)
      for (var item in cartState.items) {
         final updatedProduct = item.product.copyWith(stockQuantity: item.product.stockQuantity - item.quantity);
         await ref.read(inventoryRepositoryProvider).updateProduct(updatedProduct);
      }
      ref.invalidate(productsProvider); // Refresh inventory UI

      // 4. Print Receipt
      if (mounted) {
         await ReceiptGenerator.generateAndPrintReceipt(savedSale, saleItems, cartState.items.map((i) => i.product).toList());
      }

      // 5. Clear Cart
      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checkout successful!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBarcodeScanner(context),
              _buildSearchBar(context),
              _buildQuickActions(context),
              _buildCartList(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSummaryAndCheckout(context),
    );
  }

  Widget _buildBarcodeScanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200, // Fixed height for scanner view
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _handleBarcode(barcodes.first.rawValue!);
              }
            },
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: IconButton(
              color: Colors.white,
              icon: const Icon(Icons.flash_on),
              onPressed: () => _scannerController.toggleTorch(),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: IconButton(
              color: Colors.white,
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () => _scannerController.switchCamera(),
            ),
          ),
          Center(
            child: Container(
              width: 250,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search SKU or Product...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: _surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (value) {
            final products = ref.read(productsProvider).value ?? [];
            final match = products.where((p) => (p.sku ?? '').toLowerCase() == value.toLowerCase() || p.barcode == value).firstOrNull;
            if (match != null) {
                ref.read(cartProvider.notifier).addProduct(match);
                _searchController.clear();
            } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product not found')));
            }
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.spaceEvenly,
        children: [
          _buildActionChip(Icons.discount, 'Discount Item', onTap: () {}),
          _buildActionChip(Icons.person_add, 'Assign Customer', onTap: () {}),
          _buildActionChip(Icons.inventory_2, 'Inventory Look', onTap: () {}),
          _buildActionChip(Icons.clear_all, 'Clear Cart', color: Colors.red.shade100, iconColor: Colors.red, onTap: () {
            ref.read(cartProvider.notifier).clearCart();
          }),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, {Color? color, Color? iconColor, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color ?? _indigoLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor ?? _primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor != null ? Colors.red.shade900 : _primaryColor,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Container(
      color: _surfaceContainerLow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Session',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 16),
          if (cartState.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('Cart is empty. Scan items to add.')),
            )
          else
            ...cartState.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildCartItem(item.product, item.quantity),
                )).toList(),
        ],
      ),
    );
  }

  Widget _buildCartItem(Product product, int quantity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${product.sku}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${(product.price * quantity).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                      onTap: () => ref.read(cartProvider.notifier).updateQuantity(product, quantity - 1),
                      child: _buildQuantityButton(Icons.remove)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                      onTap: () => ref.read(cartProvider.notifier).updateQuantity(product, quantity + 1),
                      child: _buildQuantityButton(Icons.add)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 16),
    );
  }

  Widget _buildSummaryAndCheckout(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryRow('Subtotal', '\$${cartState.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Estimated Tax (8%)', '\$${cartState.estimatedTax.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Manrope',
                ),
              ),
              Text(
                '\$${cartState.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: cartState.items.isEmpty ? null : _checkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'FINALIZE CHECKOUT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDiscount ? Colors.green.shade700 : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}
