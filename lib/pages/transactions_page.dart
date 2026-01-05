import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _query = '';
  String _filterStatus = 'All';
  String _filterCustomer = '';

  final _statusOptions = const ['All', 'Paid', 'Pending', 'Canceled', 'Failed'];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  double _totalRevenue(List<Map<String, dynamic>> transactions) {
    return transactions.fold<double>(0, (sum, tx) {
      final amount = tx['amount'] ?? tx['total'] ?? 0;
      final parsed = double.tryParse(amount.toString()) ?? 0.0;
      return sum + parsed;
    });
  }

  double _totalProfit(List<Map<String, dynamic>> transactions) {
    return transactions.fold<double>(0, (sum, tx) {
      final profit = tx['profit'] ?? 0;
      final parsed = double.tryParse(profit.toString()) ?? 0.0;
      return sum + parsed;
    });
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    if (raw is DateTime) {
      final d = raw;
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    }
    return raw.toString();
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> allTransactions) {
    return allTransactions.where((tx) {
      // Search filter
      if (_query.trim().isNotEmpty) {
        final q = _query.toLowerCase();
        final itemType = (tx['itemType'] ?? '').toString().toLowerCase();
        final itemName = (tx['itemName'] ?? '').toString().toLowerCase();
        final cust = (tx['customer'] ?? '').toString().toLowerCase();
        final note = (tx['note'] ?? tx['notes'] ?? '').toString().toLowerCase();
        if (!itemType.contains(q) && !itemName.contains(q) && !cust.contains(q) && !note.contains(q)) {
          return false;
        }
      }

      // Status filter
      if (_filterStatus != 'All') {
        final txStatus = (tx['status'] ?? '').toString();
        if (txStatus.toLowerCase() != _filterStatus.toLowerCase()) {
          return false;
        }
      }

      // Customer filter
      if (_filterCustomer.trim().isNotEmpty) {
        final txCustomer = (tx['customer'] ?? '').toString().toLowerCase();
        if (!txCustomer.contains(_filterCustomer.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _showFilterDialog() async {
    String tempStatus = _filterStatus;
    final customerCtrl = TextEditingController(text: _filterCustomer);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: tempStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _statusOptions.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s),
              )).toList(),
              onChanged: (v) => tempStatus = v ?? 'All',
              isExpanded: true,
            ),
            const SizedBox(height: 16),
            const Text('Customer:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: customerCtrl,
              decoration: const InputDecoration(
                hintText: 'Filter by customer name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = 'All';
                _filterCustomer = '';
              });
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _filterStatus = tempStatus;
                _filterCustomer = customerCtrl.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _editTransaction(Map<String, dynamic> tx) async {
    final transactionId = tx['id'] as String?;
    if (transactionId == null) return;

    final customerCtrl =
        TextEditingController(text: (tx['customer'] ?? '').toString());
    final noteCtrl = TextEditingController(
        text: (tx['note'] ?? tx['notes'] ?? '').toString());
    String status = (tx['status'] ?? '').toString();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit transaction', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: customerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Customer',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status.isEmpty ? null : status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statusOptions
                    .where((s) => s.isNotEmpty)
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => status = v ?? '',
                isExpanded: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirestoreService.updateTransaction(transactionId, {
                        'customer': customerCtrl.text.trim(),
                        'notes': noteCtrl.text.trim(),
                        'status': status,
                      });
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Error updating transaction: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteTransaction(String transactionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirestoreService.deleteTransaction(transactionId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting transaction: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export_outlined),
            onPressed: () {},
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field and filter button (outside StreamBuilder to prevent rebuilds)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by item, customer or note',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor:
                          theme.inputDecorationTheme.fillColor ??
                          Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showFilterDialog,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filters'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // StreamBuilder only for the data list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: AppData.transactionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allTransactions = snapshot.data ?? [];
                final items = _filtered(allTransactions);

                return Column(
                  children: [
                    // Summary header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent transactions', style: theme.textTheme.titleMedium),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${items.length} items', style: theme.textTheme.bodySmall),
                              if (_filterStatus != 'All' || _filterCustomer.isNotEmpty)
                                Text(
                                  'Filtered',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Revenue', style: theme.textTheme.bodyMedium),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Rwf ${_totalRevenue(allTransactions).toStringAsFixed(2)}',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Profit', style: theme.textTheme.bodyMedium),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Rwf ${_totalProfit(allTransactions).toStringAsFixed(2)}',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // List
                    Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No transactions found',
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = items[index];
                      final itemType = tx['itemType'] ?? 'Unknown item';
                      final itemName = tx['itemName'] ?? '';
                      final displayText = itemName.isNotEmpty ? '$itemName ($itemType)' : itemType;
                      final date = _formatDate(tx['date']);
                      final customer = tx['customer'] ?? '';
                      final amount = tx['amount'] ?? tx['total'] ?? '';
                      final status = (tx['status'] ?? '').toString();
                      final transactionId = tx['id'] as String?;

                      Color statusColor = Colors.grey;
                      if (status.toLowerCase() == 'paid')
                        statusColor = Colors.green;
                      if (status.toLowerCase() == 'pending')
                        statusColor = Colors.orange;
                      if (status.toLowerCase() == 'canceled' ||
                          status.toLowerCase() == 'failed')
                        statusColor = Colors.red;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.12),
                            child: Icon(
                              Icons.receipt_long,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            displayText,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((customer ?? '').toString().isNotEmpty)
                                Text(customer.toString()),
                              Text(date, style: theme.textTheme.bodySmall),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    amount.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (status.toString().isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status.toString(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == 'edit' && transactionId != null) {
                                    _editTransaction(tx);
                                  } else if (value == 'delete' && transactionId != null) {
                                    _deleteTransaction(transactionId);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {},
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
    );
  }
} 
