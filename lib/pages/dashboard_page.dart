import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../services/auth_service.dart';
import 'add_item_page.dart';
import 'financials_page.dart';
import 'login_page.dart';
import 'sell_item_page.dart';
import 'stock_page.dart';
import 'transactions_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  int _totalQuantity(List<Map<String, dynamic>> items) {
    return items.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] ?? item['qty'] ?? 0) as int),
    );
  }

  double _inventoryValue(List<Map<String, dynamic>> items) {
    return items.fold<double>(0, (sum, item) {
      final qty = (item['quantity'] ?? item['qty'] ?? 0) as int;
      final price = (item['sellingPrice'] ??
              item['minimumSellingPrice'] ??
              item['selling_price'] ??
              item['price'] ??
              item['unit_price'] ??
              0)
          .toString();
      final priceVal = double.tryParse(price) ?? 0.0;
      return sum + priceVal * qty;
    });
  }

  Widget _statCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: (color ?? theme.colorScheme.primary)
                  .withOpacity(0.12),
              child: Icon(icon, color: color ?? theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
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
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget Function() pageBuilder,
    required bool isWide,
  }) {
    return SizedBox(
      width: isWide ? 140 : double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: isWide ? 10 : 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon, size: isWide ? 18 : 20),
        label: Text(label, style: TextStyle(fontSize: isWide ? 13 : 14)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => pageBuilder()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;
    final isDesktop = size.width >= 1200;
    final gridCount = isDesktop ? 3 : (isWide ? 2 : 1);
    final gridAspect = isDesktop ? 2.6 : (isWide ? 2.2 : 1.9);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AppData.stockItemsStream,
      builder: (context, itemsSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: AppData.transactionsStream,
          builder: (context, transactionsSnapshot) {
            if (itemsSnapshot.connectionState == ConnectionState.waiting ||
                transactionsSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(title: const Text('Dashboard')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            final items = itemsSnapshot.data ?? [];
            final transactions = transactionsSnapshot.data ?? [];
            final totalItems = items.length;
            final totalQty = _totalQuantity(items);
            final totalValue = _inventoryValue(items);
            final txCount = transactions.length;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Dashboard'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          // Sign out
                          await AuthService.signOut();
                          
                          // Force navigation to login by popping all routes
                          // This ensures we get back to the AuthWrapper which will show LoginPage
                          if (context.mounted) {
                            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error logging out: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      }
                    },
                    tooltip: 'Logout',
                  ),
                ],
              ),
              body: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Overview of FH Technology shop at a glance',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: gridCount,
                  shrinkWrap: true,
                  childAspectRatio: gridAspect,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _statCard(
                      context,
                      title: 'Items',
                      value: '$totalItems types',
                      icon: Icons.inventory_2_outlined,
                    ),
                    _statCard(
                      context,
                      title: 'Units in stock',
                      value: '$totalQty pcs',
                      icon: Icons.format_list_numbered,
                      color: Colors.orange,
                    ),
                    _statCard(
                      context,
                      title: 'Inventory value',
                      value: 'Rwf ${totalValue.toStringAsFixed(0)}',
                      icon: Icons.attach_money,
                      color: Colors.green,
                    ),
                    _statCard(
                      context,
                      title: 'Transactions',
                      value: '$txCount total',
                      icon: Icons.receipt_long,
                      color: Colors.blueAccent,
                    ),
                        ],
                      ),
                        const SizedBox(height: 16),
                        Text(
                          'Quick actions',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        isWide
                            ? Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _quickAction(context, icon: Icons.add, label: 'Add Item', pageBuilder: () => const AddItemPage(), isWide: isWide),
                                  _quickAction(context, icon: Icons.point_of_sale, label: 'Sell Item', pageBuilder: () => const SellItemPage(), isWide: isWide),
                                  _quickAction(context, icon: Icons.inventory, label: 'View Stock', pageBuilder: () => const StockPage(), isWide: isWide),
                                  _quickAction(context, icon: Icons.history, label: 'Transactions', pageBuilder: () => const TransactionsPage(), isWide: isWide),
                                  _quickAction(context, icon: Icons.bar_chart, label: 'Financials', pageBuilder: () => const FinancialsPage(), isWide: isWide),
                                ],
                              )
                            : Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _quickAction(context, icon: Icons.add, label: 'Add Item', pageBuilder: () => const AddItemPage(), isWide: isWide)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _quickAction(context, icon: Icons.point_of_sale, label: 'Sell Item', pageBuilder: () => const SellItemPage(), isWide: isWide)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: _quickAction(context, icon: Icons.inventory, label: 'View Stock', pageBuilder: () => const StockPage(), isWide: isWide)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _quickAction(context, icon: Icons.history, label: 'Transactions', pageBuilder: () => const TransactionsPage(), isWide: isWide)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: _quickAction(context, icon: Icons.bar_chart, label: 'Financials', pageBuilder: () => const FinancialsPage(), isWide: isWide)),
                                      const SizedBox(width: 12),
                                      const Expanded(child: SizedBox()),
                                    ],
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
