import 'package:flutter/material.dart';

// --- IMPORTS ---
import 'home_screen.dart';        
import 'trip_planner_page.dart'; 
import 'translate_page.dart'; 
import 'budget_page.dart';
import 'map_page.dart';

void main() {
  runApp(const RoamieApp());
}

class RoamieApp extends StatelessWidget {
  const RoamieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roamie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF3B82F6),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // This handles switching pages
  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen(); 
      case 1:
        return TripPlannerPage(    
          onNavigateHome: () => setState(() => _selectedIndex = 0),
        );
      case 2:
        return TranslatePage(
        onNavigateHome: () => setState(() => _selectedIndex = 0),
        );
      case 3:
        return BudgetPage(
        onNavigateHome: () => setState(() => _selectedIndex = 0),
      );
      case 4:
        return MapPage(
        onNavigateHome: () => setState(() => _selectedIndex = 0),
      );
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The error happened because your file was missing this line:
      body: _getPage(_selectedIndex), 
      
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black12, width: 0.5))
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          // And this line matches the inline function style:
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: const Color(0xFF3B82F6).withOpacity(0.2),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.location_on_outlined), selectedIcon: Icon(Icons.location_on), label: 'Plan'),
            NavigationDestination(icon: Icon(Icons.translate_outlined), selectedIcon: Icon(Icons.translate), label: 'Translate'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Budget'),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          ],
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("$title Screen", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
  }
}