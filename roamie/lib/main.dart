import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

// --- IMPORTS ---
import 'home_screen.dart';        
import 'trip_planner_page.dart'; 
import 'translate_page.dart'; 
import 'budget_page.dart';
import 'map_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
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

  // Keep single instances of each page so their state (e.g., budget history) persists
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(
        onSelectPlanTab: () => setState(() => _selectedIndex = 1),
        onSelectTranslateTab: () => setState(() => _selectedIndex = 2),
        onSelectBudgetTab: () => setState(() => _selectedIndex = 3),
        onSelectMapTab: () => setState(() => _selectedIndex = 4),
      ),
      TripPlannerPage(
        onNavigateHome: () => setState(() => _selectedIndex = 0),
      ),
      TranslatePage(
        onNavigateHome: () => setState(() => _selectedIndex = 0),
      ),
      BudgetPage(
        onNavigateHome: () => setState(() => _selectedIndex = 0),
      ),
      MapPage(
        onNavigateHome: () => setState(() => _selectedIndex = 0),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep pages alive so their state (e.g., budget entries) is not lost when switching tabs
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ), 
      
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