import 'package:flutter/material.dart';
import 'package:sales_tracker/pages/sell_item_page.dart';
import 'add_item_page.dart';
import 'view_item_page.dart';
import '../data/app_data.dart'; // import Add Item page
import 'package:cloud_firestore/cloud_firestore.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  String _query = '';
  String _filterType = 'All';
  String _filterInstalled = 'All'; // All, Installed, Not Installed
  String _filterCondition = 'All'; // All, New, Used
  
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> allItems) {
    final q = _query.trim().toLowerCase();

    return allItems.where((it) {
      // Hide out-of-stock items from the Stock page list
      final rawQty = it['quantity'] ?? it['qty'] ?? 0;
      final qty = rawQty is int ? rawQty : int.tryParse(rawQty.toString()) ?? 0;
      if (qty <= 0) return false;

      // Optional: if you ever add a persisted status field, also respect it
      final statusStr = (it['status'] ?? '').toString().toLowerCase();
      if (statusStr == 'out_of_stock') return false;

      final typeStr = (it['type'] ?? '').toString();
      if (_filterType != 'All' && typeStr != _filterType) return false;

      // Filter by installed status
      if (_filterInstalled == 'Installed' && it['installed'] != true) return false;
      if (_filterInstalled == 'Not Installed' && it['installed'] == true) return false;

      // Filter by condition
      final cond = (it['condition'] ?? '').toString();
      if (_filterCondition == 'New' && cond != 'New') return false;
      if (_filterCondition == 'Used' && cond != 'Used') return false;

      if (q.isEmpty) return true;
      final typeLower = typeStr.toLowerCase();
      final nameLower = (it['name'] ?? it['model'] ?? '').toString().toLowerCase();
      return typeLower.contains(q) || nameLower.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Stock')),
      body: Column(
        children: [
          // Search field (outside StreamBuilder to prevent rebuilds)
          Padding(
            padding: EdgeInsets.fromLTRB(isWide ? 20.0 : 16.0, isWide ? 20.0 : 16.0, isWide ? 20.0 : 16.0, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name or type',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ?? Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          
          // Filters (outside StreamBuilder to prevent rebuilds)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 20.0 : 16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterType,
                    decoration: InputDecoration(
                      labelText: 'Type',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    isExpanded: true,
                    items: <String>[
                      'All',
                      'Laptop',
                      'Storage',
                      'Other accessories',
                    ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _filterType = v ?? 'All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterInstalled,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    isExpanded: true,
                    items: <String>['All', 'Installed', 'Not Installed']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _filterInstalled = v ?? 'All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterCondition,
                    decoration: InputDecoration(
                      labelText: 'Condition',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    isExpanded: true,
                    items: <String>['All', 'New', 'Used', 'Refurbished']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _filterCondition = v ?? 'All'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // StreamBuilder only for the data list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: AppData.stockItemsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allItems = snapshot.data ?? [];
                final items = _filtered(allItems);

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isWide ? 20.0 : 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total items in stock: ${items.length}',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            '${allItems.length} overall',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Text(
                                'No stock items',
                                style: theme.textTheme.bodyLarge,
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 20 : 16,
                                8,
                                isWide ? 20 : 16,
                                90,
                              ),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final type = item['type'] ?? 'Unknown item';
                                final qty = item['quantity'] ?? item['qty'] ?? 0;
                                final price =
                                    item['sellingPrice'] ??
                                    item['minimumSellingPrice'] ??
                                    item['selling_price'] ??
                                    item['price'] ??
                                    item['unit_price'] ??
                                    '';

                                final name = item['name'] ?? item['model'] ?? '';
                                final condition = item['condition'] ?? 'Unknown';
                                final status = (qty is int && qty > 0)
                                    ? 'Available'
                                    : 'Out of stock';

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: isWide ? 20 : 16,
                                      vertical: 12,
                                    ),
                                    leading: CircleAvatar(
                                      radius: 28,
                                      backgroundColor: theme.colorScheme.primary
                                          .withOpacity(0.12),
                                      child: Icon(
                                        Icons.inventory_2,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    title: Text(
                                      name.toString(),
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 6),
                                        Text('Condition: ${condition.toString()}'),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Minimum Selling Price: ${price.toString()}',
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Status: $status',
                                          style: TextStyle(
                                            color: status == 'Available'
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Text(
                                      type.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    onTap: () {
                                      final itemId = item['id'] as String?;
                                      if (itemId != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ViewItemPage(itemId: itemId),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemPage()),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.point_of_sale),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('Sell Item'),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SellItemPage(),
                  ),
                ).then((_) => setState(() {}));
              },
            ), 
          ),
        ),
      ),
    );
  }
}
