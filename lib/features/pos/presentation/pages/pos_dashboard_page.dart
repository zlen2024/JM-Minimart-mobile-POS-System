import 'package:flutter/material.dart';

class PosDashboardPage extends StatefulWidget {
  const PosDashboardPage({Key? key}) : super(key: key);

  @override
  State<PosDashboardPage> createState() => _PosDashboardPageState();
}

class _PosDashboardPageState extends State<PosDashboardPage> {
  final Color _primaryColor = const Color(0xFF1A237E); // Deep Indigo
  final Color _surfaceColor = const Color(0xFFF8F9FA); // slate-50
  final Color _surfaceContainerLow = const Color(0xFFF3F4F5); // slightly darker background shift
  final Color _indigoLight = const Color(0xFFE8EAF6); // indigo-50

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
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.qr_code_scanner, size: 48, color: _primaryColor),
          const SizedBox(height: 12),
          const Text(
            'Position Barcode in Frame',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
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
        decoration: InputDecoration(
          hintText: 'Search SKU or Product...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: const Icon(Icons.barcode_reader),
          filled: true,
          fillColor: _surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
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
          _buildActionChip(Icons.discount, 'Discount Item'),
          _buildActionChip(Icons.person_add, 'Assign Customer'),
          _buildActionChip(Icons.inventory_2, 'Inventory Look'),
          _buildActionChip(Icons.clear_all, 'Clear Cart', color: Colors.red.shade100, iconColor: Colors.red),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, {Color? color, Color? iconColor}) {
    return Container(
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
    );
  }

  Widget _buildCartList(BuildContext context) {
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
          _buildCartItem('Vintage Denim Jacket', 'SKU: VDJ-001', '\$89.99', 1),
          const SizedBox(height: 12),
          _buildCartItem('Organic Cotton Tee', 'SKU: OCT-002', '\$24.50', 2),
          const SizedBox(height: 12),
          _buildCartItem('Leather Card Holder', 'SKU: LCH-003', '\$48.65', 1),
        ],
      ),
    );
  }

  Widget _buildCartItem(String name, String sku, String price, int quantity) {
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
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sku,
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
                price,
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
                  _buildQuantityButton(Icons.remove),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  _buildQuantityButton(Icons.add),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryRow('Subtotal', '\$187.64'),
          const SizedBox(height: 8),
          _buildSummaryRow('Estimated Tax (8%)', '\$15.01'),
          const SizedBox(height: 8),
          _buildSummaryRow('Loyalty Discount', '-\$15.01', isDiscount: true),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Manrope',
                ),
              ),
              Text(
                '\$187.64',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
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
