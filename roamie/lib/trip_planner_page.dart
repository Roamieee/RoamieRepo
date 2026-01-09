import 'package:flutter/material.dart';
import 'shared_budget.dart';
import 'itinerary_screen.dart';

// ---------------------------------------------------------------------------
// TRIP PLANNER PAGE
// ---------------------------------------------------------------------------

class TripPlannerPage extends StatefulWidget {
  final VoidCallback onNavigateHome;

  const TripPlannerPage({super.key, required this.onNavigateHome});

  @override
  State<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  bool _showItinerary = false;

  Map<String, dynamic> _tripDetails = {
    'destination': '',
    'dates': {'start': '', 'end': ''},
    'budget': '',
    'interests': <String>[],
  };

  void _handlePlanTrip(Map<String, dynamic> details) {
      // 1. Extract the data from the form map
      String destination = details['destination'] ?? "Unknown City";
      String budget = details['budget'] ?? "0";
      String dates = "${details['dates']['start']} to ${details['dates']['end']}";

      // 2. Navigate to the Itinerary Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItineraryScreen(
            destination: destination,
            budget: budget,
            dateRange: dates,
          ),
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_showItinerary) {
              setState(() => _showItinerary = false);
            } else {
              widget.onNavigateHome();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Trip Planner",
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Plan your perfect journey",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: _showItinerary
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _showItinerary = false),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text("Back to Planning"),
                  ),
                  const SizedBox(height: 16),
                  ItineraryGenerator(details: _tripDetails),
                ],
              )
            : TripPlannerForm(onPlanTrip: _handlePlanTrip),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-COMPONENTS (Form & Generator)
// ---------------------------------------------------------------------------

class TripPlannerForm extends StatefulWidget {
  final Function(Map<String, dynamic>)? onPlanTrip;
  const TripPlannerForm({super.key, this.onPlanTrip});

  @override
  State<TripPlannerForm> createState() => _TripPlannerFormState();
}

class _TripPlannerFormState extends State<TripPlannerForm> {
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _selectedInterests = {};

  final List<Map<String, dynamic>> _interestOptions = const [
    {'icon': Icons.account_balance, 'label': 'Historical Sites'},
    {'icon': Icons.restaurant_menu, 'label': 'Local Cuisine'},
    {'icon': Icons.landscape, 'label': 'Adventure'},
    {'icon': Icons.photo_camera, 'label': 'Photography'},
    {'icon': Icons.beach_access, 'label': 'Beach'},
    {'icon': Icons.shopping_bag, 'label': 'Shopping'},
  ];

  @override
  void dispose() {
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final current = isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "dd/mm/yyyy";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE65B3E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text(
          "Plan Your Perfect Journey",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          "Tell us your preferences, and we'll craft the ideal itinerary",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                  const Icon(Icons.auto_awesome, color: accent, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Trip Details",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Fill in your travel information to get started",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildLabel("Destination", icon: Icons.location_on_outlined),
              const SizedBox(height: 6),
              TextField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  hintText: "e.g., Penang, Malaysia",
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel("Start Date", icon: Icons.calendar_month_outlined),
              const SizedBox(height: 6),
              _DateField(
                label: _formatDate(_startDate),
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(height: 14),
              _buildLabel("End Date", icon: Icons.calendar_today_outlined),
              const SizedBox(height: 6),
              _DateField(
                label: _formatDate(_endDate),
                onTap: () => _pickDate(isStart: false),
              ),
              const SizedBox(height: 16),
              _buildLabel("Budget (RM)", icon: Icons.attach_money),
              const SizedBox(height: 6),
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter your budget",
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                onChanged: (value) {
                  // Update SharedBudget in real-time as user types
                  final amount = double.tryParse(value.trim());
                  if (amount != null && amount > 0) {
                    SharedBudget.budget = amount;
                  } else {
                    SharedBudget.budget = 0.0;
                  }
                },
              ),
              const SizedBox(height: 18),
              _buildLabel("Interests", icon: Icons.favorite_border),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _interestOptions.map((item) {
                  final label = item['label'] as String;
                  final selected = _selectedInterests.contains(label);
                  return ChoiceChip(
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item['icon'] as IconData, size: 16),
                        const SizedBox(width: 6),
                        Text(label),
                      ],
                    ),
                    selected: selected,
                    selectedColor: accent.withOpacity(0.12),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: selected ? accent : Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: selected ? accent : Colors.grey.shade300),
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.remove(label);
                        } else {
                          _selectedInterests.add(label);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  onPressed: () {
                    widget.onPlanTrip?.call({
                      'destination': _destinationController.text.trim(),
                      'dates': {
                        'start': _formatDate(_startDate),
                        'end': _formatDate(_endDate),
                      },
                      'budget': _budgetController.text.trim(),
                      'interests': _selectedInterests.toList(),
                    });
                  },
                  child: const Text(
                    "Generate Itinerary",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: label == "dd/mm/yyyy" ? Colors.grey[500] : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class ItineraryGenerator extends StatelessWidget {
  final Map<String, dynamic> details;
  const ItineraryGenerator({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Your AI Itinerary", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(height: 30),
          Text("Destination: ${details['destination']}"),
          Text("Budget: \$${details['budget']}"),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8)),
            child: const Text("Day 1: Arrival and Exploration...", style: TextStyle(height: 1.5, color: Color(0xFF0369A1))),
          )
        ],
      ),
    );
  }
}