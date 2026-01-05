import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../services/firestore_service.dart';
import 'add_item_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewItemPage extends StatefulWidget {
  final String itemId; // Changed from itemIndex to itemId
  const ViewItemPage({super.key, required this.itemId});

  @override
  State<ViewItemPage> createState() => _ViewItemPageState();
}

class _ViewItemPageState extends State<ViewItemPage> {
  bool _isDeleting = false;

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete item?'),
        content: const Text('This will permanently remove the item.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await FirestoreService.deleteItem(widget.itemId);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  void _edit(Map<String, dynamic> item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => AddItemPage(
          existingItem: Map.from(item),
          itemId: widget.itemId,
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value ?? '', style: const TextStyle())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: FirestoreService.getItem(widget.itemId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Item Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Item Details')),
            body: const Center(child: Text('Item not found')),
          );
        }

        final it = snapshot.data!;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(it['name'] ?? it['type'] ?? 'Item'),
            actions: [
              IconButton(
                onPressed: _isDeleting ? null : () => _edit(it),
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                onPressed: _isDeleting ? null : _delete,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Type', it['type']?.toString()),
                    _row('Name', it['name']?.toString()),
                    _row('Brand', it['brand']?.toString()),
                    _row('Buying Price', it['buyingPrice']?.toString()),
                    _row('Selling Price', it['sellingPrice']?.toString()),
                    if (it['type'] != 'Laptop')
                      _row('Quantity', it['quantity']?.toString()),
                    _row('Date', _formatDate(it['dateOfPurchase'])),
                    const Divider(),
                    // Laptop specific
                    if (it['type'] == 'Laptop') ...[
                      _row('Model', it['model']?.toString()),
                      _row('Serial', it['serial']?.toString()),
                      _row('RAM', it['ram']?.toString()),
                      _row('Storage Spec', it['storageSpec']?.toString()),
                      _row('Processor', it['processor']?.toString()),
                      _row('Condition', it['condition']?.toString()),
                      _row('Installed', it['installed']?.toString()),
                    ],
                    if (it['type'] == 'Storage') ...[
                      _row('Storage Type', it['storageType']?.toString()),
                      _row('Size', it['size']?.toString()),
                      _row('Condition', it['condition']?.toString()),
                      if (it['ramType'] != null)
                        _row('RAM Type', it['ramType']?.toString()),
                    ],
                    if (['Mouse', 'Keyboard', 'Charger'].contains(it['type'])) ...[
                      _row('Condition', it['condition']?.toString()),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(it['description']?.toString() ?? ''),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is String) {
      try {
        final dt = DateTime.parse(date);
        return '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {
        return date.toString();
      }
    }
    if (date is Timestamp) {
      final dt = date.toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    return date.toString();
  }
} 
