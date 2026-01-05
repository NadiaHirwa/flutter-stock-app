import 'package:flutter/material.dart';
import '../data/app_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FinancialsPage extends StatefulWidget {
  const FinancialsPage({super.key});

  @override
  State<FinancialsPage> createState() => _FinancialsPageState();
}

class _FinancialsPageState extends State<FinancialsPage> {
  late DateTime _selectedMonth;

  List<DateTime> get _monthOptions {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      return DateTime(date.year, date.month, 1);
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedMonth = _monthOptions.first;
  }

  List<Map<String, dynamic>> _filteredTx(List<Map<String, dynamic>> allTransactions) {
    return allTransactions.where((tx) {
      final date = tx['date'];
      if (date is! DateTime) return false;
      return date.year == _selectedMonth.year &&
          date.month == _selectedMonth.month;
    }).toList();
  }

  double _revenue(List<Map<String, dynamic>> transactions) {
    return transactions.fold<double>(0, (sum, tx) {
      final total = tx['total'] ?? tx['amount'] ?? 0;
      return sum + (double.tryParse(total.toString()) ?? 0.0);
    });
  }

  double _profit(List<Map<String, dynamic>> transactions) {
    return transactions.fold<double>(0, (sum, tx) {
      final p = tx['profit'] ?? 0;
      return sum + (double.tryParse(p.toString()) ?? 0.0);
    });
  }

  int _unitsSold(List<Map<String, dynamic>> transactions) {
    return transactions.fold<int>(0, (sum, tx) {
      final q = tx['quantity'] ?? 0;
      return sum + (int.tryParse(q.toString()) ?? 0);
    });
  }

  double _inventoryCost(List<Map<String, dynamic>> items) {
    return items.fold<double>(0, (sum, item) {
      final qty = (item['quantity'] ?? item['qty'] ?? 0) as int;
      final buy = double.tryParse((item['buyingPrice'] ?? 0).toString()) ?? 0.0;
      return sum + buy * qty;
    });
  }

  double _inventoryValue(List<Map<String, dynamic>> items) {
    return items.fold<double>(0, (sum, item) {
      final qty = (item['quantity'] ?? item['qty'] ?? 0) as int;
      final sell = double.tryParse(
              (item['sellingPrice'] ??
                      item['minimumSellingPrice'] ??
                      item['selling_price'] ??
                      item['price'] ??
                      item['unit_price'] ??
                      0)
                  .toString()) ??
          0.0;
      return sum + sell * qty;
    });
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
    Color? color,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            if (icon != null)
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    (color ?? theme.colorScheme.primary).withOpacity(0.12),
                child: Icon(icon, color: color ?? theme.colorScheme.primary),
              ),
            if (icon != null) const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color ?? theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = _monthOptions;
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;
    final isDesktop = size.width >= 1200;
    final gridCount = isDesktop ? 3 : (isWide ? 2 : 1);
    final gridAspect = isDesktop ? 2.6 : (isWide ? 2.2 : 1.9);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AppData.transactionsStream,
      builder: (context, transactionsSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: AppData.stockItemsStream,
          builder: (context, itemsSnapshot) {
            if (transactionsSnapshot.connectionState == ConnectionState.waiting ||
                itemsSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(title: const Text('Financials')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final allTransactions = transactionsSnapshot.data ?? [];
            final allItems = itemsSnapshot.data ?? [];
            final tx = _filteredTx(allTransactions);
            final revenue = _revenue(tx);
            final profit = _profit(tx);
            final margin = revenue == 0 ? 0 : (profit / revenue) * 100;
            final avgTicket = tx.isEmpty ? 0 : revenue / tx.length;
            final inventoryCost = _inventoryCost(allItems);
            final inventoryValue = _inventoryValue(allItems);
            final potentialProfit = inventoryValue - inventoryCost;
            final loss = profit < 0 ? profit.abs() : 0;

            return Scaffold(
              appBar: AppBar(title: const Text('Financials')),
              body: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Monthly financial snapshot',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            DropdownButton<DateTime>(
                              value: _selectedMonth,
                              items: months
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text('${m.year}-${m.month.toString().padLeft(2, '0')}'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedMonth = v);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: gridCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: gridAspect,
                  children: [
                    _metricCard(
                      context,
                      title: 'Revenue',
                      value: 'Rwf ${revenue.toStringAsFixed(2)}',
                      color: Colors.green[700],
                      icon: Icons.attach_money,
                    ),
                    _metricCard(
                      context,
                      title: 'Profit',
                      value: 'Rwf ${profit.toStringAsFixed(2)}',
                      color: Colors.blue[700],
                      icon: Icons.trending_up,
                    ),
                    _metricCard(
                      context,
                      title: 'Margin',
                      value: '${margin.toStringAsFixed(1)}%',
                      color: Colors.teal,
                      icon: Icons.percent,
                    ),
                    _metricCard(
                      context,
                      title: 'Transactions',
                      value: tx.length.toString(),
                      color: Colors.orange[700],
                      icon: Icons.receipt_long,
                    ),
                    _metricCard(
                      context,
                      title: 'Avg ticket',
                      value: 'Rwf ${avgTicket.toStringAsFixed(2)}',
                      color: Colors.deepPurple,
                      icon: Icons.shopping_bag_outlined,
                    ),
                    _metricCard(
                      context,
                      title: 'Units sold',
                      value: _unitsSold(tx).toString(),
                      color: Colors.brown[700],
                      icon: Icons.numbers,
                    ),
                        ],
                      ),
                        const SizedBox(height: 16),
                        Text(
                          'Balance sheet snapshot',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: gridCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: gridAspect,
                  children: [
                    _metricCard(
                      context,
                      title: 'Inventory cost',
                      value: 'Rwf ${inventoryCost.toStringAsFixed(2)}',
                      color: Colors.grey[800],
                      icon: Icons.inventory_2,
                    ),
                    _metricCard(
                      context,
                      title: 'Potential revenue',
                      value: 'Rwf ${inventoryValue.toStringAsFixed(2)}',
                      color: Colors.indigo,
                      icon: Icons.store_mall_directory,
                    ),
                    _metricCard(
                      context,
                      title: 'Potential profit',
                      value: 'Rwf ${potentialProfit.toStringAsFixed(2)}',
                      color: Colors.green[800],
                      icon: Icons.ssid_chart,
                    ),
                    _metricCard(
                      context,
                      title: 'Losses',
                      value: loss == 0 ? '—' : 'Rwf ${loss.toStringAsFixed(2)}',
                      color: Colors.red[700],
                      icon: Icons.warning_amber_rounded,
                    ),
                        ],
                      ),
                      ], 
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
