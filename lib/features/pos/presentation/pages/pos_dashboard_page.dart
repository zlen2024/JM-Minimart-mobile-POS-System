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

    final sale = Sale(
      totalAmount: cartState.total,
      paymentMethod: 'Cash',
      createdAt: DateTime.now(),
    );

    final saleItems = cartState.items.map((item) => SaleItem(
      saleId: 0,
      productId: item.product.id!,
      quantity: item.quantity,
      unitPrice: item.product.price,
    )).toList();

    try {
      final savedSale = await ref.read(posRepositoryProvider).createSale(sale, saleItems);

      for (var item in cartState.items) {
         final updatedProduct = item.product.copyWith(stockQuantity: item.product.stockQuantity - item.quantity);
         await ref.read(inventoryRepositoryProvider).updateProduct(updatedProduct);
      }
      ref.invalidate(productsProvider);

      if (mounted) {
         await ReceiptGenerator.generateAndPrintReceipt(savedSale, saleItems, cartState.items.map((i) => i.product).toList());
      }

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
      body: Stack(
        children: [
          // Background Fullscreen Scanner
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  _handleBarcode(barcodes.first.rawValue!);
                }
              },
            ),
          ),

          // Scanner Overlay Guide & Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(child: _buildSearchBar(context)),
                const SizedBox(width: 8),
                IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.flash_on),
                  onPressed: () => _scannerController.toggleTorch(),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
                IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.flip_camera_ios),
                  onPressed: () => _scannerController.switchCamera(),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
              ],
            ),
          ),

          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Draggable Cart Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.15,
            minChildSize: 0.15,
            maxChildSize: 0.8,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CartHeaderDelegate(
                        ref: ref,
                        checkoutAction: _checkout,
                        primaryColor: _primaryColor,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: _buildQuickActions(context),
                      ),
                    ),
                    _buildCartListSliver(context, ref),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search SKU / Barcode',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
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
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildActionChip(Icons.discount, 'Discount', onTap: () {}),
        _buildActionChip(Icons.person_add, 'Customer', onTap: () {}),
        _buildActionChip(Icons.clear_all, 'Clear', color: Colors.red.shade100, iconColor: Colors.red, onTap: () {
          ref.read(cartProvider.notifier).clearCart();
        }),
      ],
    );
  }

  Widget _buildActionChip(IconData icon, String label, {Color? color, Color? iconColor, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color ?? const Color(0xFFE8EAF6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor ?? _primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor != null ? Colors.red.shade900 : _primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartListSliver(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    if (cartState.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('Cart is empty. Scan items to add.'),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = cartState.items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: _buildCartItem(item.product, item.quantity, ref),
          );
        },
        childCount: cartState.items.length,
      ),
    );
  }

  Widget _buildCartItem(Product product, int quantity, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: _primaryColor,
                onPressed: () => ref.read(cartProvider.notifier).updateQuantity(product, quantity - 1),
              ),
              Text(
                '$quantity',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: _primaryColor,
                onPressed: () => ref.read(cartProvider.notifier).updateQuantity(product, quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartHeaderDelegate extends SliverPersistentHeaderDelegate {
  final WidgetRef ref;
  final VoidCallback checkoutAction;
  final Color primaryColor;

  _CartHeaderDelegate({required this.ref, required this.checkoutAction, required this.primaryColor});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cartState = ref.watch(cartProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: shrinkOffset > 0 ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: shrinkOffset > 0 ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : null,
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cartState.items.length} Items',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  Text(
                    '\$${cartState.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: cartState.items.isEmpty ? null : checkoutAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                child: const Text('Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 100.0;

  @override
  double get minExtent => 100.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
