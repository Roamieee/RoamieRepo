import 'package:flutter/material.dart';
import 'edit_itinerary_screen.dart'; 


// --- DATA MODELS ---
// We need these classes to track which items are checked/selected
class Activity {
  String time;
  String title;
  String location;
  String cost;
  bool isSelected;

  Activity({
    required this.time,
    required this.title,
    required this.location,
    required this.cost,
    this.isSelected = false,
  });
}

class DaySchedule {
  String dayTitle; // e.g., "Day 1"
  List<Activity> activities;

  DaySchedule({required this.dayTitle, required this.activities});
}

// --- MAIN SCREEN ---
class ItineraryScreen extends StatefulWidget {
    // 1. Add these variables to hold data from the previous screen
    final String destination;
    final String budget;
    final String dateRange;

    const ItineraryScreen({
        Key? key,
        required this.destination,
        required this.budget,
        required this.dateRange,
    }) : super(key: key);

    @override
    _ItineraryScreenState createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {

    // HELPER: Converts your nice GUI list back to a Text Block for editing
    String _convertScheduleToString() {
    StringBuffer buffer = StringBuffer();
    
    for (var day in schedule) {
      buffer.writeln("${day.dayTitle}:"); // e.g. "Day 1:"
      for (var activity in day.activities) {
        // Format: 09:00 AM - Visit Temple (Location)
        buffer.writeln("${activity.time} - ${activity.title} (${activity.location})");
      }
      buffer.writeln(""); // Empty line between days
    }
    
    return buffer.toString();
  }

  // DUMMY DATA (This is what your AI will eventually parse into)
  List<DaySchedule> schedule = [
    DaySchedule(
      dayTitle: "Day 1",
      activities: [
        Activity(time: "09:00 AM", title: "Georgetown Heritage Walk", location: "George Town, Penang", cost: "\$5"),
        Activity(time: "12:00 PM", title: "Lunch at Local Hawker Center", location: "Gurney Drive", cost: "\$8"),
        Activity(time: "02:00 PM", title: "Penang Hill Cable Car", location: "Penang Hill", cost: "\$15"),
      ],
    ),
    DaySchedule(
      dayTitle: "Day 2",
      activities: [
        Activity(time: "08:00 AM", title: "Visit Kek Lok Si Temple", location: "Air Itam", cost: "\$3"),
        Activity(time: "11:00 AM", title: "Explore Street Art", location: "Armenian Street", cost: "Free"),
      ],
    ),
  ];

  // LOGIC: Delete items that are checked
  void _deleteSelectedItems() {
    setState(() {
      for (var day in schedule) {
        day.activities.removeWhere((item) => item.isSelected);
      }
      // Optional: Remove empty days if you want
      // schedule.removeWhere((day) => day.activities.isEmpty);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Selected items deleted")),
    );
  }

  // LOGIC: Add a new dummy item (You can make a dialog for this later)
  void _addNewItem() {
    setState(() {
      schedule[0].activities.add(
        Activity(time: "04:00 PM", title: "New Activity Added", location: "User Location", cost: "\$10"),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light grey background like image
      appBar: AppBar(
        title: const Text("Trip Planner", style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        actions: [
            // 1. NEW EDIT BUTTON
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.teal),
            tooltip: "Fix Mistakes & Train AI",
            onPressed: () {
              // Convert current list to string
              String currentText = _convertScheduleToString();
              
              // Navigate to the Edit Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditItineraryScreen(
                    city: "Penang", // You can make this dynamic later
                    originalItinerary: currentText,
                  ),
                ),
              );
            },
          ),
          // Show Delete button only if items are selected
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteSelectedItems,
            tooltip: "Delete Selected",
          ) 
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. THE ORANGE HEADER CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE88A60), Color(0xFFF4A261)], // Orange gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your ${widget.destination} Adventure",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.white70, size: 16),
                        SizedBox(width: 5),
                        Text("2026-01-21 to 2026-01-23", style: TextStyle(color: Colors.white, fontSize: 14)),
                        SizedBox(width: 20),
                        Icon(Icons.attach_money, color: Colors.white70, size: 16),
                        Text("Budget: \$590", style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // 2. THE LIST OF DAYS
              ...schedule.map((day) => _buildDayCard(day)).toList(),
              
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
      
      // 3. ADD BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewItem,
        label: const Text("Add Place"),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFFE88A60),
      ),
    );
  }

  // WIDGET: Builds the White Card for each Day
  Widget _buildDayCard(DaySchedule day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day.dayTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Build list of activities inside this day
            ...day.activities.map((activity) => _buildActivityTile(activity)).toList(),
          ],
        ),
      ),
    );
  }

  // WIDGET: The individual row (Time - Title - Checkbox)
  Widget _buildActivityTile(Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              activity.time,
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(activity.location, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
                    Text(activity.cost, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Checkbox logic
          Checkbox(
            value: activity.isSelected,
            activeColor: Colors.orange,
            shape: const CircleBorder(), // Makes it round like the image
            onChanged: (bool? value) {
              setState(() {
                activity.isSelected = value!;
              });
            },
          )
        ],
      ),
    );
  }
}