import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- DATA MODEL FOR EDITING ---
// This helps us manage each bubble separately instead of one big text block
class EditableActivity {
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
  // We now store a List of objects instead of one big string
  List<EditableActivity> _activities = [];
  bool _isSaving = false;
  
  // MATCHING YOUR APP THEME
  final Color _accentColor = const Color(0xFFE65B3E); 

  @override
  void initState() {
    super.initState();
    _parseItinerary();
  }

  // Helper: Parses the text block into editable objects (Cards)
  void _parseItinerary() {
    List<String> lines = widget.originalItinerary.split('\n');
    
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      if (line.contains("Day")) continue; // Skip "Day 1" headers to keep simple

      // Heuristic: Try to split "09:00 AM - Activity Name (Location)"
      if (line.contains("-")) {
        var parts = line.split("-");
        String time = parts[0].trim();
        String rest = parts.sublist(1).join("-").trim();
        
        String title = rest;
        String location = "";
        
        // Extract location if inside brackets ()
        if (rest.contains("(") && rest.contains(")")) {
          int start = rest.lastIndexOf("(");
          int end = rest.lastIndexOf(")");
          title = rest.substring(0, start).trim();
          location = rest.substring(start + 1, end).trim();
        }

        _activities.add(EditableActivity(time: time, title: title, location: location));
      }
    }
    
    // Fallback: If parsing fails, create one editable card with the whole text
    if (_activities.isEmpty) {
      _activities.add(EditableActivity(time: "09:00 AM", title: widget.originalItinerary, location: widget.city));
    }
  }

  @override
  void dispose() {
    for (var activity in _activities) {
      activity.titleController.dispose();
      activity.locationController.dispose();
    }
    super.dispose();
  }

  // Feature: Show Clock to pick time
  Future<void> _pickTime(int index) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: _accentColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _activities[index].time = picked.format(context);
      });
    }
  }

  // Helper: Rebuilds the final string for the AI to learn
  String _generateFinalString() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("Day 1:"); // Hardcoded for simplicity
    for (var item in _activities) {
      buffer.writeln("${item.time} - ${item.titleController.text} (${item.locationController.text})");
    }
    return buffer.toString();
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
          // Orange Header Hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            color: _accentColor.withOpacity(0.1),
            width: double.infinity,
            child: Row(
              children: [
                Icon(Icons.auto_fix_high, color: _accentColor, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Tap any item to edit. Your changes teach the AI.",
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // List of Editable Cards
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _activities.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _activities[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // Row 1: Time Picker & Delete Button
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _pickTime(index),
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
                            onTap: () => setState(() => _activities.removeAt(index)),
                            child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Row 2: Activity Title Input
                      TextField(
                        controller: item.titleController,
                        decoration: const InputDecoration(
                          labelText: "Activity",
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Row 3: Location Input
                      TextField(
                        controller: item.locationController,
                        decoration: const InputDecoration(
                          labelText: "Location",
                          prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Floating Button to Add New Card
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _activities.add(EditableActivity(time: "12:00 PM", title: "", location: ""));
          });
        },
        backgroundColor: _accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}