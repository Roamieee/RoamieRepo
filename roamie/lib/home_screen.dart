import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeaderSection(),
          const SizedBox(height: 24),
          const FeaturesGrid(),
          const SizedBox(height: 32),
          const QuickActionSection(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-COMPONENTS (Header, Grid, etc.)
// ---------------------------------------------------------------------------

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("ROAMIE", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text("Your AI Travel Companion", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
                ],
              ),
              Icon(Icons.flight, size: 40, color: Colors.white.withOpacity(0.8)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ready for your next adventure?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text("Start planning your perfect trip today", style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
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

class FeaturesGrid extends StatelessWidget {
  const FeaturesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      FeatureItem(Icons.location_on, "Plan Your Trip", "AI-powered itinerary generation", [Colors.blue, Colors.blueAccent]),
      FeatureItem(Icons.translate, "Translate", "Real-time translation tools", [Colors.teal, Colors.tealAccent]),
      FeatureItem(Icons.account_balance_wallet, "Budget Tracker", "Track your expenses", [Colors.purple, Colors.purpleAccent]),
      FeatureItem(Icons.map, "Interactive Map", "Explore destinations", [Colors.blue, Colors.teal]),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Features", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) => FeatureCard(item: features[index]),
          ),
        ],
      ),
    );
  }
}

class QuickActionSection extends StatelessWidget {
  const QuickActionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Quick Start", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text("Start Planning Your Trip", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;
  FeatureItem(this.icon, this.title, this.description, this.gradientColors);
}

class FeatureCard extends StatelessWidget {
  final FeatureItem item;
  const FeatureCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48, height: 48, margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: item.gradientColors),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: Colors.white, size: 24),
          ),
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}