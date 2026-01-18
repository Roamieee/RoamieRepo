import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackService {
  // Call this function when the user clicks "Save Correction"
  Future<void> sendCorrection(String city, String userEditedItinerary) async {
    
    CollectionReference queue = FirebaseFirestore.instance.collection('training_queue');

    try {
      await queue.add({
        'instruction': "Generate a travel itinerary for $city.",
        'input': "User Feedback Loop", 
        'output': userEditedItinerary, // This is the "Gold" data
        'status': 'pending', // Python will look for this
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("✅ Success! Feedback sent to the database.");
    } catch (e) {
      print("❌ Error sending feedback: $e");
    }
  }
}