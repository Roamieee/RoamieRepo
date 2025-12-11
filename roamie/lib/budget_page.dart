import 'package:flutter/material.dart';

class BudgetPage extends StatelessWidget {
  final VoidCallback onNavigateHome;

  const BudgetPage({super.key, required this.onNavigateHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: onNavigateHome,
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
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: BudgetTracker(totalBudget: 1000.0),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// COMPONENT: Budget Tracker UI (styled like the mock) + mock logic
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

    setState(() {
      _expenses.insert(0, {
        'category': _selectedCategory,
        'amount': amount,
        'description': description.isEmpty ? _selectedCategory : description,
      });
      _amountController.clear();
      _descriptionController.clear();
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
        const SizedBox(height: 6),
        const Text(
          "Budget Tracker",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          "Keep track of your spending in real-time",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 18),
        _buildOverviewCard(spentText, remainingText, progress),
        const SizedBox(height: 18),
        _buildAddExpenseCard(),
      ],
    );
  }

  Widget _buildOverviewCard(String spentText, String remainingText, double progress) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Budget Overview",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statColumn("Total Budget", "\$${widget.totalBudget.toStringAsFixed(0)}", Colors.black),
              _statColumn("Spent", "\$$spentText", Colors.deepOrange),
              _statColumn("Remaining", "\$$remainingText", const Color(0xFF00A3D7)),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "Budget Used",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00A3D7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add Expense",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          const Text(
            "Category",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _categories.map((cat) {
              final selected = cat['label'] == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat['label'] as String),
                child: Container(
                  width: 110,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? Colors.deepOrange : Colors.grey.shade300, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat['icon'] as IconData, color: selected ? Colors.deepOrange : Colors.grey[700], size: 26),
                      const SizedBox(height: 8),
                      Text(
                        cat['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.deepOrange : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            "Amount (\$)",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: "0.00",
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Description",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: "What did you buy?",
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _addExpense,
              child: const Text(
                "Add",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}