import 'package:flutter/material.dart';
import 'transactions_page.dart';
import '../data/app_data.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellItemPage extends StatefulWidget {
  final Map<String, dynamic>? existingItem;
  final String? itemId; // Changed from itemIndex to itemId

  const SellItemPage({super.key, this.existingItem, this.itemId});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  String searchQuery = '';
  Map<String, dynamic>? selectedItem;
  String? selectedItemId; // Changed from selectedIndex to selectedItemId

  final TextEditingController searchCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController(text: '1');
  final TextEditingController sellingPriceCtrl = TextEditingController();
  final TextEditingController customerCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      selectedItem = Map<String, dynamic>.from(widget.existingItem!);
      selectedItemId = widget.itemId ?? selectedItem?['id'] as String?;
      sellingPriceCtrl.text =
          (selectedItem?['sellingPrice'] ??
                  selectedItem?['selling_price'] ??
                  '')
              .toString();
      qtyCtrl.text = (selectedItem?['quantity'] ?? selectedItem?['qty'] ?? 1)
          .toString();
    } else if (widget.itemId != null) {
      // Load item from Firebase if only itemId is provided
      _loadItem(widget.itemId!);
    }
  }

  Future<void> _loadItem(String itemId) async {
    try {
      final item = await FirestoreService.getItem(itemId);
      if (item != null && mounted) {
        setState(() {
          selectedItem = item;
          selectedItemId = itemId;
          final stockQty = (item['quantity'] ?? item['qty'] ?? 1) as int;
          final itemTotalSelling = double.tryParse(
                (item['sellingPrice'] ??
                        item['minimumSellingPrice'] ??
                        item['selling_price'] ??
                        '0')
                    .toString(),
              ) ??
              0.0;
          final unitMin = stockQty > 0 ? itemTotalSelling / stockQty : itemTotalSelling;
          qtyCtrl.text = '1';
          sellingPriceCtrl.text = (unitMin * 1).toStringAsFixed(2);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading item: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    qtyCtrl.dispose();
    sellingPriceCtrl.dispose();
    customerCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> filteredItems(List<Map<String, dynamic>> allItems) {
    final q = searchQuery.trim().toLowerCase();
    return allItems.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final type = (item['type'] ?? '').toString().toLowerCase();
      final serial = (item['serial'] ?? item['sku'] ?? '')
          .toString()
          .toLowerCase();
      final model = (item['model'] ?? '').toString().toLowerCase();
      if (q.isEmpty) return true;
      return name.contains(q) ||
          type.contains(q) ||
          serial.contains(q) ||
          model.contains(q);
    }).toList();
  }

  double get total {
    // sellingPriceCtrl holds the total price for the selected quantity
    return double.tryParse(sellingPriceCtrl.text) ?? 0.0;
  }

  double get profit {
    if (selectedItem == null) return 0.0;
    final stockQty =
        (selectedItem?['quantity'] ?? selectedItem?['qty'] ?? 1) as int;
    final buyingTotal =
        double.tryParse(
          (selectedItem?['buyingPrice'] ?? selectedItem?['buying_price'] ?? '0')
              .toString(),
        ) ??
        0.0;
    final unitBuying = stockQty > 0 ? buyingTotal / stockQty : buyingTotal;
    final sellQty = int.tryParse(qtyCtrl.text) ?? 1;
    final sellingTotal = double.tryParse(sellingPriceCtrl.text) ?? 0.0;
    final costForSold = unitBuying * sellQty;
    return sellingTotal - costForSold;
  }

  Future<void> _confirmSale() async {
    if (selectedItem == null || selectedItemId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select an item to sell.')));
      return;
    }

    final qtyRaw = qtyCtrl.text.trim();
    final priceRaw = sellingPriceCtrl.text.trim();
    final sellQty = int.tryParse(qtyRaw);
    final sellingTotal = double.tryParse(priceRaw);
    final stockQty =
        (selectedItem?['quantity'] ?? selectedItem?['qty'] ?? 1) as int;

    final itemTotalSelling =
        double.tryParse(
          (selectedItem?['sellingPrice'] ??
                  selectedItem?['minimumSellingPrice'] ??
                  selectedItem?['selling_price'] ??
                  '0')
              .toString(),
        ) ??
        0.0;
    final unitMinPrice = stockQty > 0
        ? itemTotalSelling / stockQty
        : itemTotalSelling;

    final buyingTotal =
        double.tryParse(
          (selectedItem?['buyingPrice'] ?? selectedItem?['buying_price'] ?? '0')
              .toString(),
        ) ??
        0.0;
    final unitBuying = stockQty > 0 ? buyingTotal / stockQty : buyingTotal;

    if (qtyRaw.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quantity is required')));
      return;
    }
    if (sellQty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be a whole number')),
      );
      return;
    }
    if (sellQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be at least 1')),
      );
      return;
    }
    if (sellQty > stockQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough stock (available: $stockQty)')),
      );
      return;
    }

    if (priceRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selling price is required')),
      );
      return;
    }
    if (sellingTotal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selling price must be a number')),
      );
      return;
    }
    if (sellingTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selling price must be greater than 0')),
      );
      return;
    }

    // Minimum allowed for this sale = unitMinPrice * sellQty
    final minAllowed = unitMinPrice * sellQty;
    if (sellingTotal < minAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selling total is below minimum allowed (Rwf ${minAllowed.toStringAsFixed(2)})',
          ),
        ),
      );
      return;
    }

    try {
      // Calculate unit prices
      final unitSalePrice = sellingTotal / sellQty;
      final calculatedProfit = sellingTotal - (unitBuying * sellQty);

      // Create transaction in Firebase
      await FirestoreService.addTransaction({
        'itemId': selectedItemId, // Store as reference
        'itemType': selectedItem?['type'] ?? '',
        'itemName': selectedItem?['name'] ?? selectedItem?['model'] ?? '',
        'quantity': sellQty,
        'unitPrice': unitSalePrice,
        'total': sellingTotal,
        'profit': calculatedProfit,
        'buyingPrice': unitBuying, // Unit buying price at time of sale
        'sellingPrice': unitSalePrice, // Unit selling price at time of sale
        'customer': customerCtrl.text.trim(),
        'notes': notesCtrl.text.trim(),
        'date': DateTime.now(),
      });

      // Update stock item in Firebase
      if (sellQty >= stockQty) {
        // Remove item completely
        await FirestoreService.deleteItem(selectedItemId!);
      } else {
        // Update remaining quantity and prices
        final remaining = stockQty - sellQty;
        await FirestoreService.updateItem(selectedItemId!, {
          'quantity': remaining,
          'sellingPrice': unitMinPrice * remaining,
          'buyingPrice': unitBuying * remaining,
        });
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing sale: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Sell Item')),
      body: Column(
        children: [
          // Search field (outside StreamBuilder to prevent rebuilds)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 24 : 16,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search item (name, serial, model)',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => searchQuery = v),
                ),
              ),
            ),
          ),
          
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
                final items = filteredItems(allItems);

                // List of items
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 24 : 16,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final name =
                            item['name'] ??
                            item['model'] ??
                            item['type'] ??
                            'Item';
                        final itemId = item['id'] as String?;
                        final isSelected = selectedItemId == itemId;
                        
                        return ListTile(
                          title: Text(name.toString()),
                          subtitle: Text(item['type']?.toString() ?? ''),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            setState(() {
                              selectedItem = item;
                              selectedItemId = itemId;
                              final stockQty =
                                  (item['quantity'] ?? item['qty'] ?? 1) as int;
                              final itemTotalSelling =
                                  double.tryParse(
                                    (item['sellingPrice'] ??
                                            item['minimumSellingPrice'] ??
                                            item['selling_price'] ??
                                            '0')
                                        .toString(),
                                  ) ??
                                  0.0;
                              final unitMin = stockQty > 0
                                  ? itemTotalSelling / stockQty
                                  : itemTotalSelling;
                              // default sell quantity to 1 to encourage partial sales
                              qtyCtrl.text = '1';
                              // prefill selling total as unitMin * qty
                              sellingPriceCtrl.text =
                                  (unitMin * (int.tryParse(qtyCtrl.text) ?? 1))
                                      .toStringAsFixed(2);
                            });
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Selected item form (fixed at bottom, outside StreamBuilder)
          if (selectedItem != null)
            Container(
              constraints: const BoxConstraints(maxWidth: 900),
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 24 : 16,
                vertical: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Divider(),

                    // Selected item info
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Selling: ${selectedItem!['name'] ?? selectedItem!['type']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            'Stock: ${selectedItem!['quantity'] ?? selectedItem!['qty'] ?? 1}',
                          ),
                        ],
                      ),
                    ),

                    // Quantity + Price
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: sellingPriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText:
                                  'Selling Price (total for selected quantity)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Customer
                    TextField(
                      controller: customerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Customer (optional)',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Total & Profit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total: Rwf ${total.toStringAsFixed(2)}'),
                        Text('Profit: Rwf ${profit.toStringAsFixed(2)}'),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirmSale,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text('Confirm Sale'),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TransactionsPage(),
                          ),
                        );
                      },
                      child: const Text('View All Transactions'),
                    ),
                  ],
                ),
              ),
            ),

        ],
      ),
    );
  }
}
