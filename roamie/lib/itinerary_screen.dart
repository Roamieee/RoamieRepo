import 'package:flutter/material.dart';
import 'edit_itinerary_screen.dart'; 

// --- DATA MODELS ---
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
  String dayTitle; 
  List<Activity> activities;

  DaySchedule({required this.dayTitle, required this.activities});
}

// --- MAIN SCREEN ---
class ItineraryScreen extends StatefulWidget {
  final String destination;
  final String budget;
  final String dateRange;
  
  // --- NEW: This was missing! ---
  final String? aiResponse; 

  const ItineraryScreen({
    Key? key,
    required this.destination,
    required this.budget,
    required this.dateRange,
    this.aiResponse, // <--- Now it accepts the data
  }) : super(key: key);

  @override
  _ItineraryScreenState createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  List<DaySchedule> schedule = [];

  @override
  void initState() {
    super.initState();
    // Check if we have real AI data or need dummy data
    if (widget.aiResponse != null && widget.aiResponse!.isNotEmpty) {
      _parseAiResponse(widget.aiResponse!);
    } else {
      _loadDummyData();
    }
  }

  // --- PARSER: Turns AI Text into List Objects ---
  void _parseAiResponse(String response) {
    try {
      List<DaySchedule> parsedSchedule = [];
      List<String> days = response.split(RegExp(r"Day \d+:"));
      
      if (days.isNotEmpty && days[0].trim().isEmpty) days.removeAt(0);

      int dayCount = 1;
      for (String dayText in days) {
        List<Activity> activities = [];
        List<String> lines = dayText.split('\n');
        
        for (String line in lines) {
          if (line.trim().isEmpty) continue;
          if (line.contains("-") || line.contains(":")) {
             activities.add(Activity(
               time: "Flexible", 
               title: line.replaceAll(RegExp(r"^\d+\.\s*"), "").trim(), 
               location: widget.destination, 
               cost: "-"
             ));
          }
        }
        
        if (activities.isNotEmpty) {
          parsedSchedule.add(DaySchedule(dayTitle: "Day $dayCount", activities: activities));
          dayCount++;
        }
      }

      setState(() {
        schedule = parsedSchedule;
      });
      
    } catch (e) {
      print("Error parsing AI: $e");
      _loadDummyData();
    }
  }

  void _loadDummyData() {
    schedule = [
      DaySchedule(
        dayTitle: "Day 1 (Demo)",
        activities: [
          Activity(time: "09:00 AM", title: "Arrival", location: widget.destination, cost: "-"),
          Activity(time: "12:00 PM", title: "Lunch", location: "City Center", cost: "\$10"),
        ],
      ),
    ];
  }

  // HELPER: Converts list to text for editing
  String _convertScheduleToString() {
    if (widget.aiResponse != null) return widget.aiResponse!;

    StringBuffer buffer = StringBuffer();
    for (var day in schedule) {
      buffer.writeln("${day.dayTitle}:"); 
      for (var activity in day.activities) {
        buffer.writeln("${activity.time} - ${activity.title}");
      }
      buffer.writeln(""); 
    }
    return buffer.toString();
  }

  void _deleteSelectedItems() {
    setState(() {
      for (var day in schedule) {
        day.activities.removeWhere((item) => item.isSelected);
      }
    });
  }

  void _addNewItem() {
    if (schedule.isEmpty) return;
    setState(() {
      schedule[0].activities.add(
        Activity(time: "TBD", title: "New Activity", location: "-", cost: "-"),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(
        title: const Text("Trip Planner", style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        
        // Back Button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

        actions: [
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.teal),
            tooltip: "Edit & Train",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditItineraryScreen(
                    city: widget.destination,
                    originalItinerary: _convertScheduleToString(),
                  ),
                ),
              );
            },
          ),
          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteSelectedItems,
          ) 
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE88A60), Color(0xFFF4A261)],
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
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Colors.white70, size: 16),
                        const SizedBox(width: 5),
                        Text(widget.dateRange, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(width: 20),
                        const Icon(Icons.attach_money, color: Colors.white70, size: 16),
                        Text("Budget: \$${widget.budget}", style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // List of Activities
              if (schedule.isEmpty) 
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("No itinerary generated yet."),
                )
              else 
                ...schedule.map((day) => _buildDayCard(day)).toList(),
              
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewItem,
        label: const Text("Add Place"),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFFE88A60),
      ),
    );
  }

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
            ...day.activities.map((activity) => _buildActivityTile(activity)).toList(),
          ],
        ),
      ),
    );
  }

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
                  ],
                ),
              ],
            ),
          ),
          Checkbox(
            value: activity.isSelected,
            activeColor: Colors.orange,
            shape: const CircleBorder(),
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