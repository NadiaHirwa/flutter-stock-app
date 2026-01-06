import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddItemPage extends StatefulWidget {
  final Map<String, dynamic>? existingItem;
  final String? itemId; // Changed from itemIndex to itemId

  const AddItemPage({super.key, this.existingItem, this.itemId});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _buyPriceCtrl = TextEditingController();
  final _sellPriceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String selectedItemType = 'Laptop';
  DateTime? purchaseDate;
  bool _isLoading = false;
  bool _isInitializing = true;

  final List<String> itemTypes = ['Laptop', 'Storage', 'Other accessories'];

  // Additional controllers / fields for specific item types
  final _modelCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _ramCtrl = TextEditingController();
  final _storageSpecCtrl = TextEditingController();
  final _processorCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  String _condition = 'New';
  bool _installed = false;
  String _storageType = 'SSD';
  String _ramType = 'DDR4';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _quantityCtrl.dispose();
    _descriptionCtrl.dispose();
    _modelCtrl.dispose();
    _serialCtrl.dispose();
    _ramCtrl.dispose();
    _storageSpecCtrl.dispose();
    _processorCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadExistingItem();
  }

  Future<void> _loadExistingItem() async {
    // If itemId is provided but existingItem is not, load from Firebase
    if (widget.itemId != null && widget.existingItem == null) {
      setState(() => _isInitializing = true);
      try {
        final item = await FirestoreService.getItem(widget.itemId!);
        if (item != null && mounted) {
          _populateFields(item);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading item: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isInitializing = false);
        }
      }
    } else if (widget.existingItem != null) {
      _populateFields(widget.existingItem!);
      setState(() => _isInitializing = false);
    } else {
      // Set default quantity for bulk items
      _quantityCtrl.text = '1';
      setState(() => _isInitializing = false);
    }
  }

  void _populateFields(Map<String, dynamic> existing) {
    selectedItemType = existing['type'] ?? selectedItemType;
    _nameCtrl.text = existing['name'] ?? '';
    _brandCtrl.text = existing['brand'] ?? '';
    _buyPriceCtrl.text = (existing['buyingPrice'] ?? '').toString();
    _sellPriceCtrl.text = (existing['sellingPrice'] ?? '').toString();
    _quantityCtrl.text = (existing['quantity'] ?? 1).toString();
    if (existing['dateOfPurchase'] != null) {
      try {
        if (existing['dateOfPurchase'] is String) {
          purchaseDate = DateTime.parse(existing['dateOfPurchase']);
        } else if (existing['dateOfPurchase'] is Timestamp) {
          purchaseDate = (existing['dateOfPurchase'] as Timestamp).toDate();
        }
      } catch (_) {}
    }
    _descriptionCtrl.text = existing['description'] ?? '';

    // type-specific
    _modelCtrl.text = existing['model'] ?? '';
    _serialCtrl.text = existing['serial'] ?? '';
    _ramCtrl.text = existing['ram'] ?? '';
    _storageSpecCtrl.text = existing['storageSpec'] ?? '';
    _processorCtrl.text = existing['processor'] ?? '';
    _sizeCtrl.text = existing['size'] ?? '';
    _condition = existing['condition'] ?? _condition;
    _installed = existing['installed'] ?? _installed;
    _storageType = existing['storageType'] ?? _storageType;
    if (existing['ramType'] != null) {
      _ramType = existing['ramType'] ?? _ramType;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: purchaseDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null) setState(() => purchaseDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    // Editing existing item is admin-only
    if (widget.itemId != null && !AuthService.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the owner can edit existing items.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Determine quantity based on item type
      final isBulkItem = selectedItemType != 'Laptop';
      final quantity = isBulkItem ? int.tryParse(_quantityCtrl.text) ?? 1 : 1;

      final map = <String, dynamic>{
        'type': selectedItemType,
        'name': _nameCtrl.text.trim().isEmpty
            ? '${selectedItemType} Item'
            : _nameCtrl.text.trim(),
        'brand': _brandCtrl.text.trim(),
        'buyingPrice': double.tryParse(_buyPriceCtrl.text) ?? 0.0,
        'sellingPrice': double.tryParse(_sellPriceCtrl.text) ?? 0.0,
        'quantity': quantity,
        'dateOfPurchase': purchaseDate?.toIso8601String(),
        'description': _descriptionCtrl.text.trim(),
      };

      // Add specific fields depending on type
      if (selectedItemType == 'Laptop') {
        map.addAll({
          'model': _modelCtrl.text.trim(),
          'serial': _serialCtrl.text.trim(),
          'ram': _ramCtrl.text.trim(),
          'storageSpec': _storageSpecCtrl.text.trim(),
          'processor': _processorCtrl.text.trim(),
          'condition': _condition,
          'installed': _installed,
        });
      } else if (['Other accessories'].contains(selectedItemType)) {
        map.addAll({'condition': _condition});
      } else if (selectedItemType == 'Storage') {
        map.addAll({
          'storageType': _storageType,
          'size': _sizeCtrl.text.trim(),
          'condition': _condition,
          if (_storageType == 'RAM') 'ramType': _ramType,
        });
      }

      // Save to Firebase
      if (widget.itemId != null) {
        // Update existing item
        await FirestoreService.updateItem(widget.itemId!, map);
      } else {
        // Add new item
        await FirestoreService.addItem(map);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;
    
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Item')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId != null ? 'Edit Item' : 'Add Item'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 24 : 16,
          vertical: 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedItemType,
                          decoration: const InputDecoration(
                            labelText: 'Item Type',
                          ),
                          items: itemTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(
                            () => selectedItemType = v ?? selectedItemType,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          purchaseDate == null
                              ? 'Pick Date'
                              : '${purchaseDate!.day}/${purchaseDate!.month}/${purchaseDate!.year}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _brandCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _buyPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Buying Price',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            final parsed = double.tryParse(v);
                            if (parsed == null) return 'Enter a valid number';
                            if (parsed < 0) return 'Must be zero or more';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sellPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: selectedItemType == 'Laptop'
                                ? 'Minimum Selling Price'
                                : 'Minimum Selling Price (for full quantity)',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            final parsed = double.tryParse(v);
                            if (parsed == null) return 'Enter a valid number';
                            if (parsed <= 0) return 'Must be greater than zero';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Quantity field for bulk items only
                  if (selectedItemType != 'Laptop')
                    TextFormField(
                      controller: _quantityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final parsed = int.tryParse(v);
                        if (parsed == null) return 'Enter a valid number';
                        if (parsed <= 0) return 'Must be greater than zero';
                        return null;
                      },
                    ),

                  if (selectedItemType != 'Laptop') const SizedBox(height: 12),

                  TextFormField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 12),

                  // --- Type-specific fields ---
                  if (selectedItemType == 'Laptop') ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Laptop Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _modelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Model / Type',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _serialCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Serial Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ramCtrl,
                      decoration: const InputDecoration(
                        labelText: 'RAM (e.g. 8GB)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _storageSpecCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Storage (e.g. 512GB SSD)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _processorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Processor',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _condition,
                            decoration: const InputDecoration(
                              labelText: 'Condition',
                            ),
                            items: ['New', 'Used', 'Refurbished']
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _condition = v ?? _condition),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              const Text('Installed'),
                              const SizedBox(width: 8),
                              Switch(
                                value: _installed,
                                onChanged: (v) =>
                                    setState(() => _installed = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else if ([
                    'Other accessories',
                  ].contains(selectedItemType)) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Accessory Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _condition,
                      decoration: const InputDecoration(labelText: 'Condition'),
                      items: ['New', 'Used']
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _condition = v ?? _condition),
                    ),
                  ] else if (selectedItemType == 'Storage') ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Storage Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _storageType,
                            decoration: const InputDecoration(
                              labelText: 'Storage Type',
                            ),
                            items:
                                [
                                      'SSD',
                                      'HDD',
                                      'External SSD',
                                      'External HDD',
                                      'Flash',
                                      'RAM',
                                    ]
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(
                              () => _storageType = v ?? _storageType,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _sizeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Size (e.g. 256GB)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_storageType == 'RAM') ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _ramType,
                        decoration: const InputDecoration(
                          labelText: 'RAM Type',
                        ),
                        items: const ['DDR3', 'DDR4', 'DDR5']
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _ramType = v ?? _ramType),
                      ),
                    ],
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _condition,
                      decoration: const InputDecoration(labelText: 'Condition'),
                      items: ['New', 'Used']
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _condition = v ?? _condition),
                    ),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Item',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ),
                ], 
              ),
            ),
          ),
        ),
      ),
    );
  }
}
