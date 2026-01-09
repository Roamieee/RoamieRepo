import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- DATA MODELS ---
// We use an abstract class so our list can hold BOTH Headers and Activities
abstract class ItineraryItem {}

class DayHeader extends ItineraryItem {
  final String title; // e.g., "Day 1"
  DayHeader(this.title);
}

class EditableActivity extends ItineraryItem {
  String time;
  TextEditingController titleController;
  TextEditingController locationController;

  EditableActivity({
    required this.time,
    required String title,
    required String location,
  })  : titleController = TextEditingController(text: title),
        locationController = TextEditingController(text: location);
}

// --- SCREEN ---
class EditItineraryScreen extends StatefulWidget {
  final String city;
  final String originalItinerary;

  const EditItineraryScreen({
    Key? key,
    required this.city,
    required this.originalItinerary,
  }) : super(key: key);

  @override
  _EditItineraryScreenState createState() => _EditItineraryScreenState();
}

class _EditItineraryScreenState extends State<EditItineraryScreen> {
  // This list now holds mixed items (Headers AND Activities)
  List<ItineraryItem> _items = [];
  bool _isSaving = false;
  
  final Color _accentColor = const Color(0xFFE65B3E); 

  @override
  void initState() {
    super.initState();
    _parseItinerary();
  }

  void _parseItinerary() {
    List<String> lines = widget.originalItinerary.split('\n');
    bool hasFoundDay = false;
    
    for (String line in lines) {
      String cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;

      // 1. DETECT DAY HEADER
      if (cleanLine.startsWith("Day")) {
        // Clean up text (e.g. "Day 1:" -> "Day 1")
        String title = cleanLine.replaceAll(":", "").trim();
        _items.add(DayHeader(title));
        hasFoundDay = true;
        continue;
      }

      // 2. DETECT ACTIVITY
      if (cleanLine.contains("-")) {
        // Try to split "09:00 AM - Activity Name (Location)"
        var parts = cleanLine.split("-");
        String time = parts[0].trim();
        String rest = parts.sublist(1).join("-").trim();
        
        String title = rest;
        String location = "";
        
        if (rest.contains("(") && rest.contains(")")) {
          int start = rest.lastIndexOf("(");
          int end = rest.lastIndexOf(")");
          title = rest.substring(0, start).trim();
          location = rest.substring(start + 1, end).trim();
        }

        _items.add(EditableActivity(time: time, title: title, location: location));
      }
    }
    
    // Fallback: If AI didn't write "Day 1", insert it at the top
    if (!hasFoundDay && _items.isNotEmpty) {
      _items.insert(0, DayHeader("Day 1"));
    }
  }

  @override
  void dispose() {
    for (var item in _items) {
      if (item is EditableActivity) {
        item.titleController.dispose();
        item.locationController.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _pickTime(EditableActivity item) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: _accentColor)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        item.time = picked.format(context);
      });
    }
  }

  // Reconstruct the text with Days included
  String _generateFinalString() {
    StringBuffer buffer = StringBuffer();
    
    for (var item in _items) {
      if (item is DayHeader) {
        buffer.writeln("\n${item.title}:"); // Add empty line before days
      } else if (item is EditableActivity) {
        buffer.writeln("${item.time} - ${item.titleController.text} (${item.locationController.text})");
      }
    }
    return buffer.toString().trim();
  }

  Future<void> _saveAndTrainAI() async {
    setState(() => _isSaving = true);
    try {
      String finalOutput = _generateFinalString();

      await FirebaseFirestore.instance.collection('training_queue').add({
        'instruction': "Generate a travel itinerary for ${widget.city}.",
        'input': "User Correction/Feedback", 
        'output': finalOutput, 
        'status': 'pending', 
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Corrections sent! The AI will learn from this."), backgroundColor: Colors.green),
      );
      Navigator.pop(context); 

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Edit Plan", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveAndTrainAI,
            child: _isSaving 
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _accentColor))
              : Text("SAVE", style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: _accentColor.withOpacity(0.1),
            width: double.infinity,
            child: Row(
              children: [
                Icon(Icons.auto_fix_high, color: _accentColor, size: 20),
                const SizedBox(width: 10),
                const Expanded(child: Text("Tap items to edit. Drag to reorder (coming soon).", style: TextStyle(fontSize: 12))),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];

                // --- CASE 1: DAY HEADER ---
                if (item is DayHeader) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 10, left: 5),
                    child: Text(
                      item.title, // e.g. "Day 1"
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  );
                }

                // --- CASE 2: EDITABLE CARD ---
                if (item is EditableActivity) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12), // Spacing between cards
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () => _pickTime(item),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: Colors.grey[700]),
                                    const SizedBox(width: 6),
                                    Text(item.time, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => setState(() => _items.removeAt(index)),
                              child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: item.titleController,
                          decoration: const InputDecoration(labelText: "Activity", isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.all(12)),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: item.locationController,
                          decoration: const InputDecoration(labelText: "Location", prefixIcon: Icon(Icons.location_on_outlined, size: 18), isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.all(12)),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      // Add Activity Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            // Find where to add: defaults to end
            _items.add(EditableActivity(time: "12:00 PM", title: "", location: ""));
          });
        },
        backgroundColor: _accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}