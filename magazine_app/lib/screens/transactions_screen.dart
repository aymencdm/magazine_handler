import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import '../models/borrow_transaction.dart';
import '../models/group.dart';
import '../models/student.dart';
import '../models/material.dart' as app_material;
import '../models/category.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ApiService _apiService = ApiService();
  List<BorrowTransaction> _transactions = [];
  List<Group> _groups = [];
  List<Student> _allStudents = [];
  List<app_material.Material> _materials = [];
  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('DEBUG: Starting full data refresh...');
    await Future.wait([
      _loadTransactions(),
      _loadGroups(),
      _loadStudents(),
      _loadMaterials(),
      _loadCategories(),
    ].map((e) => e as Future<dynamic>).toList());
    print('DEBUG: Data refresh complete.');
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _apiService.getTransactions();
      print('DEBUG: Loaded ${transactions.length} transactions.');
      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    } catch (e) {
      print('DEBUG: Error loading transactions: $e');
      if (mounted) {
        setState(() => _loading = false);
        _showErrorSnackBar('Error loading transactions: $e');
      }
    }
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _apiService.getGroups();
      print('DEBUG: Loaded ${groups.length} groups.');
      setState(() {
        _groups = groups;
      });
    } catch (e) {
      print('DEBUG: Error loading groups: $e');
      if (mounted) _showErrorSnackBar('Error loading groups: $e');
    }
  }

  Future<void> _loadStudents() async {
    try {
      final students = await _apiService.getStudents();
      print('DEBUG: Loaded ${students.length} students.');
      setState(() {
        _allStudents = students;
      });
    } catch (e) {
      print('DEBUG: Error loading students: $e');
      if (mounted) _showErrorSnackBar('Error loading students: $e');
    }
  }

  Future<void> _loadMaterials() async {
    try {
      final materials = await _apiService.getMaterials();
      print('DEBUG: Loaded ${materials.length} materials.');
      setState(() {
        _materials = materials;
      });
    } catch (e) {
      print('DEBUG: Error loading materials: $e');
      if (mounted) _showErrorSnackBar('Error loading materials: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      print('DEBUG: Loaded ${categories.length} categories.');
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('DEBUG: Error loading categories: $e');
      if (mounted) _showErrorSnackBar('Error loading categories: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _getCategoryDisplayName(Category cat) {
    if (cat.parentName != null && cat.parentName!.isNotEmpty) {
      return "${cat.parentName} > ${cat.name}";
    }
    return cat.name;
  }

  @override
  Widget build(BuildContext context) {
    // Filter transactions for each tab
    final nothingReturned = _transactions.where((t) => t.status.toUpperCase() == 'BORROWED').toList();
    final partiallyReturned = _transactions.where((t) => t.status.toUpperCase() == 'PARTIALLY_RETURNED').toList();
    final fullyReturned = _transactions.where((t) => t.status.toUpperCase() == 'RETURNED').toList();

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Borrow Transactions',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () => _showNewTransactionDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('New Transaction'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TabBar(
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Nothing Returned'),
                      if (nothingReturned.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${nothingReturned.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Returned Some'),
                      if (partiallyReturned.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${partiallyReturned.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Fully Returned'),
                      if (fullyReturned.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${fullyReturned.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildTransactionList(nothingReturned, 'No borrowed items currently.'),
                        _buildTransactionList(partiallyReturned, 'No partially returned items.'),
                        _buildTransactionList(fullyReturned, 'No completed returns.'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<BorrowTransaction> transactions, String emptyMessage) {
    if (transactions.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final displayName = transaction.groupName.isNotEmpty 
            ? transaction.groupName 
            : transaction.studentName;
            
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            onExpansionChanged: (expanded) {
              print('DEBUG: ExpansionTile changed to: $expanded for transaction ${transaction.id}');
            },
            leading: Icon(
              transaction.status.toUpperCase() == 'BORROWED'
                  ? Icons.arrow_upward
                  : transaction.status.toUpperCase() == 'RETURNED'
                      ? Icons.arrow_downward
                      : Icons.swap_horiz,
              color: transaction.status.toUpperCase() == 'BORROWED'
                  ? Colors.orange
                  : transaction.status.toUpperCase() == 'RETURNED'
                      ? Colors.green
                      : Colors.blue,
            ),
            title: InkWell(
              onTap: transaction.group != null 
                ? () {
                    print('DEBUG: Clicked group name: ${transaction.groupName}');
                    final group = _groups.firstWhere((g) => g.id == transaction.group);
                    _showGroupDialogFromTransaction(group);
                  }
                : null,
              child: Text(
                displayName,
                style: transaction.group != null 
                    ? const TextStyle(decoration: TextDecoration.underline, color: Colors.blue)
                    : null,
              ),
            ),
            subtitle: Text(
              '${transaction.borrowDate.toString().substring(0, 10)} • ${transaction.status}',
            ),
            trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (transaction.hasPdf)
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        onPressed: () => _openPdf(transaction),
                        tooltip: 'Open PDF',
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteTransaction(transaction),
                      tooltip: 'Delete Transaction',
                    ),
                  ],
                ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Borrowed Items:', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...transaction.borrowedItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${item.materialName} (${item.categoryName})')),
                          Text('Qty: ${item.quantityBorrowed} / Returned: ${item.quantityReturned}'),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (transaction.status != 'RETURNED')
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ElevatedButton.icon(
                              onPressed: () => _showReturnDialog(transaction),
                              icon: const Icon(Icons.assignment_return),
                              label: const Text('Return Materials'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        if (!transaction.hasPdf)
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Generating PDF...')),
                                );
                                
                                await _apiService.generatePdf(transaction.id!);
                                _loadTransactions(); // refresh
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('PDF generated successfully')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  _showErrorSnackBar('Error: $e');
                                }
                              }
                            },
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Generate PDF'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteTransaction(BorrowTransaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this transaction for ${transaction.groupName}? This will restore all remaining items to inventory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteTransaction(transaction.id!);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) _showErrorSnackBar('Error deleting transaction: $e');
      }
    }
  }

  void _showReturnDialog(BorrowTransaction transaction) {
    final formKey = GlobalKey<FormState>();
    // Track return quantities: {itemId: controller}
    final Map<int, TextEditingController> qtyControllers = {};
    for (var item in transaction.borrowedItems) {
      final remaining = item.quantityBorrowed - item.quantityReturned;
      qtyControllers[item.id!] = TextEditingController(text: remaining.toString());
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Return Materials - ${transaction.groupName.isNotEmpty ? transaction.groupName : transaction.studentName}'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter quantities to return for each item:'),
                  const SizedBox(height: 16),
                  ...transaction.borrowedItems.map((item) {
                    final remaining = item.quantityBorrowed - item.quantityReturned;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.materialName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Borrowed: ${item.quantityBorrowed} | Returned: ${item.quantityReturned}', 
                                     style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: qtyControllers[item.id!],
                              decoration: const InputDecoration(
                                labelText: 'Return Qty',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                final qty = int.tryParse(value);
                                if (qty == null) return 'Invalid';
                                if (qty < 0) return 'Negative';
                                if (qty > remaining) return 'Max $remaining';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final List<Map<String, dynamic>> returnItems = [];
                qtyControllers.forEach((itemId, controller) {
                  final qty = int.parse(controller.text);
                  if (qty > 0) {
                    returnItems.add({
                      'item_id': itemId,
                      'quantity_returned': qty,
                    });
                  }
                });

                if (returnItems.isEmpty) {
                  _showErrorSnackBar('Please return at least one item');
                  return;
                }

                try {
                  print('DEBUG: Calling returnItems API...');
                  await _apiService.returnItems(transaction.id!, returnItems);
                  print('DEBUG: returnItems API success.');
                  if (context.mounted) {
                    Navigator.pop(context);
                    print('DEBUG: Refreshing data after return...');
                    _loadData(); // Full refresh to update material quantities
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Items returned successfully')),
                    );
                  }
                } catch (e) {
                  print('DEBUG: Error returning items: $e');
                  if (context.mounted) {
                    _showErrorSnackBar('Error: $e');
                  }
                }
              }
            },
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    );
  }

  void _showNewTransactionDialog() {
    if (_groups.isEmpty) {
      _showErrorSnackBar('Please add groups first');
      return;
    }
    // Filter out materials with 0 quantity initially just to check availability
    final availableMaterials = _materials.where((m) => m.availableQuantity > 0).toList();
    if (availableMaterials.isEmpty) {
      _showErrorSnackBar('No materials available for borrowing');
      return;
    }

    final formKey = GlobalKey<FormState>();
    int? selectedGroupId = _groups.isNotEmpty ? _groups[0].id : null;
    
    // Structure: List of objects to track selections in UI
    // Each item: {category_id: int?, material_id: int?, quantity: int}
    List<Map<String, dynamic>> selectedItems = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Borrow Transaction'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 700,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedGroupId,
                      decoration: const InputDecoration(labelText: 'Select Group'),
                      items: _groups.map((group) {
                        return DropdownMenuItem(
                          value: group.id,
                          child: Text(group.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedGroupId = value;
                        });
                      },
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Materials to Borrow', style: Theme.of(context).textTheme.titleMedium),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedItems.add({
                                'category_id': null,
                                'material_id': null,
                                'quantity': 1,
                              });
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (selectedItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Click "Add Item" to select materials.'),
                      ),
                    ...selectedItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      
                      // Filter materials based on selected category AND > 0 quantity
                      List<app_material.Material> categoryMaterials = [];
                      if (item['category_id'] != null) {
                        categoryMaterials = _materials.where((m) => 
                          m.category == item['category_id'] && m.availableQuantity > 0
                        ).toList();
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Category Selection
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<int>(
                                  value: item['category_id'],
                                  decoration: const InputDecoration(labelText: 'Category'),
                                  items: _categories.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat.id,
                                      child: Text(_getCategoryDisplayName(cat)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedItems[index]['category_id'] = value;
                                      selectedItems[index]['material_id'] = null; // Reset material
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Material Selection
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  value: item['material_id'],
                                  decoration: const InputDecoration(labelText: 'Material'),
                                  items: categoryMaterials.map((mat) {
                                    return DropdownMenuItem(
                                      value: mat.id,
                                      child: Text('${mat.name} (Avail: ${mat.availableQuantity})'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedItems[index]['material_id'] = value!;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Quantity
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  initialValue: item['quantity'].toString(),
                                  decoration: const InputDecoration(labelText: 'Qty'),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Req';
                                    final qty = int.tryParse(value!);
                                    if (qty == null || qty <= 0) return 'Invalid';
                                    
                                    if (item['material_id'] != null) {
                                      final mat = _materials.firstWhere((m) => m.id == item['material_id']);
                                      if (qty > mat.availableQuantity) return 'Max ${mat.availableQuantity}';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    final qty = int.tryParse(value);
                                    if (qty != null) {
                                      setState(() {
                                        selectedItems[index]['quantity'] = qty;
                                      });
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    selectedItems.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate() && selectedItems.isNotEmpty) {
                  try {
                    // Convert to List<Map<String, dynamic>> for API
                    final items = selectedItems.map((item) => {
                      'material_id': item['material_id'],
                      'quantity_borrowed': item['quantity'],
                    }).toList();
                    
                    print('DEBUG: Calling createTransaction API...');
                    await _apiService.createTransaction(
                      groupId: selectedGroupId!,
                      items: items,
                    );
                    print('DEBUG: createTransaction API success.');
                    if (context.mounted) {
                      Navigator.pop(context);
                      print('DEBUG: Refreshing data after create...');
                      _loadData(); // Full refresh to update material quantities
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction created successfully')),
                      );
                    }
                  } catch (e) {
                    print('DEBUG: Error creating transaction: $e');
                    if (context.mounted) {
                      // Show detailed error in dialog
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Error Creating Transaction'),
                          content: Text(e.toString()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                } else if (selectedItems.isEmpty) {
                  _showErrorSnackBar('Please add at least one item');
                }
              },
              child: const Text('Create Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPdf(BorrowTransaction transaction) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      
      // Sanitized group name for folder creation
      // If groupName is empty (individual student), use "Individual_Students" or similar
      String cleanName = transaction.groupName.isNotEmpty 
          ? transaction.groupName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') 
          : 'Individual_Students';
          
      final groupDir = Directory('${documentsDir.path}${Platform.pathSeparator}$cleanName');
      if (!await groupDir.exists()) {
        await groupDir.create(recursive: true);
      }

      final filePath = '${groupDir.path}${Platform.pathSeparator}transaction_${transaction.id}.pdf';
      final file = File(filePath);

      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading PDF...')),
          );
        }
        await _apiService.downloadPdf(transaction.id!, filePath);
      }

      // Open the file/folder
      if (Platform.isWindows) {
        // explorer /select, <path> opens explorer with the file selected
        await Process.run('explorer', ['/select,', filePath]);
      } else if (Platform.isLinux) {
        // xdg-open opens the file in default viewer. To open folder, we pass directory.
        // But user asked to "send me to it", usually implying seeing the file in folder context.
        // For now, let's open the directory for consistency with the request "folder with the groups name"
        await Process.run('xdg-open', [groupDir.path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', filePath]); // -R reveals in Finder
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Error opening PDF: $e');
    }
  }

  void _showGroupDialogFromTransaction(Group group) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: group.name);
    
    // Track selected student IDs
    List<int> selectedStudentIds = group.students.map((s) => s.id).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Group Members'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Group Name'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Members', style: Theme.of(context).textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: () => _showAddStudentDialog(setState),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Student'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _allStudents.isEmpty 
                      ? const Center(child: Text('No students available. Add students first.'))
                      : ListView.builder(
                        itemCount: _allStudents.length,
                        itemBuilder: (context, index) {
                          final student = _allStudents[index];
                          final isSelected = selectedStudentIds.contains(student.id);
                          return CheckboxListTile(
                            title: Text(student.fullName),
                            subtitle: Text(student.idCardNumber),
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedStudentIds.add(student.id);
                                } else {
                                  selectedStudentIds.remove(student.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  if (selectedStudentIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least one student')),
                    );
                    return;
                  }

                  try {
                    final updatedGroupName = nameController.text;
                    await _apiService.updateGroup(group.id, updatedGroupName, selectedStudentIds);
                    if (context.mounted) {
                      Navigator.pop(context);
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Group updated successfully')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) _showErrorSnackBar('Error: $e');
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog(StateSetter parentSetState) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final idCardController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Student'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: idCardController,
                decoration: const InputDecoration(labelText: 'ID Card Number'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final newStudent = Student(
                    id: 0,
                    fullName: nameController.text,
                    idCardNumber: idCardController.text,
                    phoneNumber: '', 
                    email: '',           // Added missing required field
                    transactionsCount: 0, // Added missing required field
                    createdAt: DateTime.now(), // Added missing required field
                    updatedAt: DateTime.now(), // Added missing required field
                  );
                  await _apiService.createStudent(newStudent);
                  await _loadStudents(); // Refresh global list
                  parentSetState(() {}); // Refresh dialog list
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) _showErrorSnackBar('Error: $e');
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
