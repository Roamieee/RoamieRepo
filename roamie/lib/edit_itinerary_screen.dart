import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the text box with the itinerary passed from the previous screen
    _controller = TextEditingController(text: widget.originalItinerary);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- FIREBASE LOGIC ---
  Future<void> _saveAndTrainAI() async {
    // 1. Show loading spinner
    setState(() => _isSaving = true);

    try {
      // 2. Send the corrected text to Firebase
      // Python will see this "pending" status and use it for training
      await FirebaseFirestore.instance.collection('training_queue').add({
        'instruction': "Generate a travel itinerary for ${widget.city}.",
        'input': "User Correction/Feedback", 
        'output': _controller.text, // This is the EDITED version
        'status': 'pending', 
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 3. Show Success Message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Corrections sent! The AI will learn from this."),
          backgroundColor: Colors.teal,
        ),
      );

      // 4. Close the screen
      Navigator.pop(context); 

    } catch (e) {
      // Handle Errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    } finally {
      // Stop loading spinner
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Edit ${widget.city} Plan",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        // We explicitly add a back button that closes the screen
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // This creates the "Back" action
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Fix mistakes below. Your edits will be used to train the Roamie AI model.",
                      style: TextStyle(color: Colors.blueGrey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 15),
            
            // --- THE EDITING AREA ---
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null, // Allows infinite lines
                  expands: true,  // Fills the container
                  style: const TextStyle(fontSize: 16, height: 1.5, fontFamily: "monospace"),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Type your itinerary here...",
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // --- THE SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAndTrainAI,
                icon: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _isSaving ? "Sending to Brain..." : "Save Corrections",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}