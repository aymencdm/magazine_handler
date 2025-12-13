import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  
  // Statistics
  int _totalStudents = 0;
  int _totalMaterials = 0;
  int _activeBorrowings = 0;
  int _lowStockItems = 0;
  int _categoriesCount = 0;
  int _pdfsGenerated = 0;
  
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Fetch data in parallel
      final results = await Future.wait([
        _apiService.getStudents(),
        _apiService.getMaterials(),
        _apiService.getTransactions(),
        _apiService.getCategories(),
      ]);

      final students = results[0] as List<dynamic>;
      final materials = results[1] as List<dynamic>;
      final transactions = results[2] as List<dynamic>;
      final categories = results[3] as List<dynamic>;

      // Calculate stats
      final activeTransactions = transactions.where((t) => t.status == 'borrowed').toList();
      final lowStock = (materials as List<dynamic>).where((m) => m.availableQuantity < 5).toList();
      final pdfsCount = transactions.where((t) => t.hasPdf).length;

      if (mounted) {
        setState(() {
          _totalStudents = students.length;
          _totalMaterials = materials.length;
          _activeBorrowings = activeTransactions.length;
          _lowStockItems = lowStock.length;
          _categoriesCount = categories.length;
          _pdfsGenerated = pdfsCount;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading dashboard: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadStats,
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  context,
                  'Total Students',
                  _totalStudents.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Total Materials',
                  _totalMaterials.toString(),
                  Icons.inventory,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Active Borrowings',
                  _activeBorrowings.toString(),
                  Icons.swap_horiz,
                  Colors.orange,
                ),
                _buildStatCard(
                  context,
                  'Low Stock Items',
                  _lowStockItems.toString(),
                  Icons.warning,
                  Colors.red,
                ),
                _buildStatCard(
                  context,
                  'Categories',
                  _categoriesCount.toString(),
                  Icons.category,
                  Colors.purple,
                ),
                _buildStatCard(
                  context,
                  'PDFs Generated',
                  _pdfsGenerated.toString(),
                  Icons.picture_as_pdf,
                  Colors.teal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
