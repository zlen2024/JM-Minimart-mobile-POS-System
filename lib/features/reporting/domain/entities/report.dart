class SalesReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final double totalCost;
  final int totalTransactions;

  double get totalProfit => totalRevenue - totalCost;

  SalesReport({
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalTransactions,
  });
}

class DailySalesData {
  final DateTime date;
  final double amount;

  DailySalesData(this.date, this.amount);
}
