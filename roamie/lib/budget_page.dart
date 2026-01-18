import 'package:flutter/material.dart';
import 'dart:async';
import 'shared_budget.dart';

class BudgetPage extends StatefulWidget {
  final VoidCallback onNavigateHome;

  const BudgetPage({super.key, required this.onNavigateHome});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Rebuild every 500ms to reflect budget changes from trip planner
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onNavigateHome,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Budget Tracker",
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Manage your expenses",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: BudgetTracker(totalBudget: SharedBudget.budget),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// COMPONENT: Budget Tracker UI + History Logic
// ---------------------------------------------------------------------------

class BudgetTracker extends StatefulWidget {
  final double totalBudget;

  const BudgetTracker({super.key, required this.totalBudget});

  @override
  State<BudgetTracker> createState() => _BudgetTrackerState();
}

class _BudgetTrackerState extends State<BudgetTracker> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Each expense is a Map containing id, category, amount, description, and date
  final List<Map<String, dynamic>> _expenses = [];

  final List<Map<String, dynamic>> _categories = const [
    {'label': 'Food', 'icon': Icons.restaurant_menu},
    {'label': 'Transport', 'icon': Icons.directions_car},
    {'label': 'Accommodation', 'icon': Icons.apartment},
    {'label': 'Activities', 'icon': Icons.sports_esports},
    {'label': 'Shopping', 'icon': Icons.shopping_bag},
    {'label': 'Other', 'icon': Icons.attach_money},
  ];

  String _selectedCategory = 'Food';

  double get _totalSpent => _expenses.fold(0.0, (sum, e) => sum + (e['amount'] as double));
  double get _remaining => widget.totalBudget - _totalSpent;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addExpense() {
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(amountText) ?? 0;
    
    if (amount <= 0) return;

    // Check if adding this expense will exceed the budget
    final newTotal = _totalSpent + amount;
    if (newTotal > widget.totalBudget) {
      final exceededAmount = newTotal - widget.totalBudget;
      _showBudgetExceededAlert(amount, exceededAmount);
      return;
    }

    setState(() {
      _expenses.insert(0, {
        'id': DateTime.now().toString(), // unique ID for deletion
        'category': _selectedCategory,
        'amount': amount,
        'description': description.isEmpty ? _selectedCategory : description,
        'timestamp': DateTime.now(),
      });
      _amountController.clear();
      _descriptionController.clear();
      FocusScope.of(context).unfocus(); // Close keyboard
    });
  }

  void _showBudgetExceededAlert(double amount, double exceededAmount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
            const SizedBox(width: 10),
            const Text('Budget Exceeded!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adding this expense of RM${amount.toStringAsFixed(2)} will exceed your planned budget.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Current Budget:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('RM${widget.totalBudget.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Already Spent:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('RM${_totalSpent.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('RM${_remaining.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Over Budget By:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        'RM${exceededAmount.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Would you like to add it anyway?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _forceAddExpense();
            },
            child: const Text('Add Anyway', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _forceAddExpense() {
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(amountText) ?? 0;
    
    if (amount <= 0) return;

    setState(() {
      _expenses.insert(0, {
        'id': DateTime.now().toString(),
        'category': _selectedCategory,
        'amount': amount,
        'description': description.isEmpty ? _selectedCategory : description,
        'timestamp': DateTime.now(),
      });
      _amountController.clear();
      _descriptionController.clear();
      FocusScope.of(context).unfocus();
    });
  }

  void _removeExpense(String id) {
    setState(() {
      _expenses.removeWhere((item) => item['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final spentText = _totalSpent.toStringAsFixed(2);
    final remainingText = _remaining.toStringAsFixed(2);
    final progress = (_totalSpent / widget.totalBudget).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Real-time Spending",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        _buildOverviewCard(spentText, remainingText, progress),
        const SizedBox(height: 20),
        _buildAddExpenseCard(),
        const SizedBox(height: 24),
        _buildHistorySection(),
      ],
    );
  }

  Widget _buildOverviewCard(String spentText, String remainingText, double progress) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline, color: Color(0xFF00A3D7), size: 22),
              SizedBox(width: 8),
              Text(
                "Budget Summary",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statColumn("Budget", "RM${widget.totalBudget.toInt()}", Colors.black87),
              _statColumn("Spent", "RM$spentText", Colors.redAccent),
              _statColumn("Remaining", "RM$remainingText", const Color(0xFF00A3D7)),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                progress > 0.9 ? Colors.red : const Color(0xFF00A3D7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAddExpenseCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Add New Expense", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("Category", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final selected = cat['label'] == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['label'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? Colors.deepOrange.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? Colors.deepOrange : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(cat['icon'] as IconData, size: 16, color: selected ? Colors.deepOrange : Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          cat['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.deepOrange : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          Column(
            children: [
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixText: "RM ",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Description",
                  hintText: "E.g. Coffee",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _addExpense,
              child: const Text("Add Expense", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Expense History",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (_expenses.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text("No expenses recorded yet.", style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _expenses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final expense = _expenses[index];
              final categoryData = _categories.firstWhere(
                (c) => c['label'] == expense['category'],
                orElse: () => {'icon': Icons.help_outline},
              );

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(categoryData['icon'] as IconData, color: Colors.deepOrange, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense['description'],
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          Text(
                            expense['category'],
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "-RM${(expense['amount'] as double).toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _removeExpense(expense['id']),
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.grey, fontSize: 11, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}