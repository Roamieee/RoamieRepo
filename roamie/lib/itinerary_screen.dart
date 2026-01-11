import 'package:flutter/material.dart';
import 'edit_itinerary_screen.dart'; 

// --- DATA MODELS ---
class Activity {
  String time;
  String title;
  String category; // We'll call this 'category' to be clear (was location)
  String cost;

  Activity({
    required this.time,
    required this.title,
    required this.category,
    required this.cost,
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
  final String? aiResponse; 

  const ItineraryScreen({
    Key? key,
    required this.destination,
    required this.budget,
    required this.dateRange,
    this.aiResponse, 
  }) : super(key: key);

  @override
  _ItineraryScreenState createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  String? _currentRawItinerary;
  List<DaySchedule> schedule = [];
  final Color _themeOrange = const Color(0xFFE65B3E);

  @override
  void initState() {
    super.initState();
    _currentRawItinerary = widget.aiResponse;

    if (widget.aiResponse != null && widget.aiResponse!.isNotEmpty) {
      _parseAiResponse(widget.aiResponse!);
    } else {
      _loadDummyData();
    }
  }

  // --- 🛠️ THE FIX: SMART BLOCK PARSER ---
  void _parseAiResponse(String response) {
    _currentRawItinerary = response;
    try {
      List<DaySchedule> parsedSchedule = [];
      
      // 1. Split by "Day X:"
      List<String> days = response.split(RegExp(r"Day \d+:"));
      if (days.isNotEmpty && days[0].trim().isEmpty) days.removeAt(0);

      int dayCount = 1;
      for (String dayText in days) {
        List<Activity> activities = [];

        // 2. Find ALL occurrences of "HH:MM AM/PM"
        // This splits the single big paragraph into separate activities
        final timeRegex = RegExp(r"(\d{1,2}:\d{2}\s*[AP]M)");
        final matches = timeRegex.allMatches(dayText).toList();

        for (int i = 0; i < matches.length; i++) {
          final currentMatch = matches[i];
          final nextMatch = (i + 1 < matches.length) ? matches[i + 1] : null;

          // A. Extract Time
          String time = currentMatch.group(1) ?? "TBD";

          // B. Extract Content (Text between this time and the next time)
          int start = currentMatch.end; 
          // Skip the dash if it exists right after the time (e.g. "09:00 AM -")
          if (start < dayText.length && (dayText[start] == '-' || dayText[start] == '–')) {
            start++; 
          }
          
          int end = (nextMatch != null) ? nextMatch.start : dayText.length;
          String fullContent = dayText.substring(start, end).trim();

          // Clean up trailing punctuation (periods/commas from previous sentence)
          fullContent = fullContent.replaceAll(RegExp(r"[.,;]+$"), "");

          // C. Extract Category (The fix for "General")
          String title = fullContent;
          String category = "General"; 

          // Regex: Finds text inside parentheses at the end of the string
          // e.g. "Visit Museum (Historical Site)" -> Group 1 is "Historical Site"
          final categoryRegex = RegExp(r"\(([^)]+)\)$");
          final catMatch = categoryRegex.firstMatch(fullContent);

          if (catMatch != null) {
            category = catMatch.group(1)?.trim() ?? "General";
            // Remove the category from the title so it looks clean
            title = fullContent.replaceAll(categoryRegex, "").trim();
          }

          // --- 🔧 FIX: REMOVE LEADING DASHES ---
          // This regex removes any hyphen (-) or en-dash (–) at the start, 
          // plus any spaces immediately following it.
          title = title.replaceFirst(RegExp(r"^[-–]\s*"), "");

          activities.add(Activity(
            time: time, 
            title: title, 
            category: category, 
            cost: "-"
          ));
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
          Activity(time: "09:00 AM", title: "Georgetown Heritage Walk", category: "History", cost: "-"),
          Activity(time: "12:00 PM", title: "Lunch at Hawker Center", category: "Food", cost: "-"),
        ],
      ),
    ];
  }

  String _convertScheduleToString() {
    // Return the updated variable, fallback to widget, then empty
    return _currentRawItinerary ?? widget.aiResponse ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: const Text("Trip Planner", style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: _themeOrange),
            onPressed: () async {
              // 2. Add 'await' and capture the result
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditItineraryScreen(
                    city: widget.destination,
                    // Use the current state, not just the widget's initial response
                    originalItinerary: _convertScheduleToString(), 
                  ),
                ),
              );

              // 3. Check if we got data back
              if (result != null && result is String) {
                print("Received updated itinerary!"); // Debug print
                
                // 4. Update the UI
                // We explicitly call your parser with the NEW string
                _parseAiResponse(result);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // HEADER CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE88A60), Color(0xFFF4A261)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your ${widget.destination} Adventure",
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(widget.dateRange, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        const SizedBox(width: 20),
                        const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text("Budget: \$${widget.budget}", style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),

              if (schedule.isEmpty) 
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Generating your itinerary...", style: TextStyle(color: Colors.grey)),
                )
              else 
                ...schedule.map((day) => _buildDayCard(day)).toList(),
              
              const SizedBox(height: 50), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(DaySchedule day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Text(
            day.dayTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        ...day.activities.map((activity) => _buildActivityTile(activity)).toList(),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildActivityTile(Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TIME BOX
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              activity.time, 
              style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE (Now clean, without category)
                Text(
                  activity.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                
                // CATEGORY ROW (Displays "Historical Site", "Local Cuisine", etc.)
                Row(
                  children: [
                    Icon(Icons.category, size: 14, color: Colors.grey[500]), 
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.category, 
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}