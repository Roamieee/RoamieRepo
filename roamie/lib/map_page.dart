import 'package:flutter/material.dart';

class MapPage extends StatelessWidget {
  final VoidCallback onNavigateHome;

  const MapPage({super.key, required this.onNavigateHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: onNavigateHome,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Map",
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Explore destinations",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: _MapContent(),
      ),
    );
  }
}

class _MapContent extends StatelessWidget {
  const _MapContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        SizedBox(height: 4),
        Text(
          "Map",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 6),
        Text(
          "Explore destinations",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        SizedBox(height: 16),
        _FilterRow(),
        SizedBox(height: 10),
        _MapView(),
        SizedBox(height: 12),
        _SearchBar(),
      ],
    );
  }
}

class _FilterRow extends StatefulWidget {
  const _FilterRow();

  @override
  State<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends State<_FilterRow> {
  bool showHiddenGems = true;
  bool showHotspots = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildChip(
            label: "Hidden Gems",
            icon: Icons.diamond,
            active: showHiddenGems,
            onTap: () => setState(() => showHiddenGems = !showHiddenGems),
          ),
          const SizedBox(width: 12),
          _buildChip(
            label: "Hotspots",
            icon: Icons.local_fire_department,
            active: showHotspots,
            onTap: () => setState(() => showHotspots = !showHotspots),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF96446) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : Colors.orange),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  final List<Map<String, dynamic>> _markers = [
    {'label': 'Redang Island', 'category': 'hotspot', 'x': 0.32, 'y': 0.42},
    {'label': 'Hidden Beach', 'category': 'gem', 'x': 0.28, 'y': 0.47},
    {'label': 'Lagoon Point', 'category': 'gem', 'x': 0.36, 'y': 0.52},
    {'label': 'Coral Cove', 'category': 'hotspot', 'x': 0.41, 'y': 0.49},
    {'label': 'Bay Village', 'category': 'hotspot', 'x': 0.56, 'y': 0.45},
    {'label': 'Reef Edge', 'category': 'gem', 'x': 0.62, 'y': 0.36},
    {'label': 'Sunset Key', 'category': 'hotspot', 'x': 0.82, 'y': 0.54},
    {'label': 'Pearl Drop', 'category': 'gem', 'x': 0.72, 'y': 0.64},
    {'label': 'Islet Point', 'category': 'hotspot', 'x': 0.78, 'y': 0.68},
  ];

  String _activeFilter = 'all'; // 'all', 'gem', 'hotspot'
  Map<String, dynamic>? _selectedMarker;

  @override
  Widget build(BuildContext context) {
    final markers = _markers.where((m) {
      if (_activeFilter == 'all') return true;
      return m['category'] == _activeFilter;
    }).toList();

    return Column(
      children: [
        Container(
          height: 520,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey.shade100, Colors.white],
                  ),
                ),
              ),
              // map watermark placeholder
              Positioned(
                bottom: 12,
                left: 12,
                child: Opacity(
                  opacity: 0.5,
                  child: Row(
                    children: const [
                      Icon(Icons.map, size: 18, color: Colors.grey),
                      SizedBox(width: 6),
                      Text("mapbox", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              // markers
              ...markers.map((m) {
                final color = m['category'] == 'hotspot' ? const Color(0xFFF96446) : const Color(0xFF21B5D3);
                return Positioned(
                  left: m['x'] * MediaQuery.of(context).size.width * 0.75,
                  top: m['y'] * 520,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMarker = m),
                    child: Column(
                      children: [
                        Icon(
                          m['category'] == 'hotspot' ? Icons.local_fire_department : Icons.diamond,
                          color: color,
                          size: 24,
                        ),
                        Icon(Icons.location_on, color: color, size: 34),
                      ],
                    ),
                  ),
                );
              }).toList(),
              // zoom controls
              Positioned(
                right: 10,
                top: 20,
                child: Column(
                  children: [
                    _zoomButton(Icons.add),
                    const SizedBox(height: 8),
                    _zoomButton(Icons.remove),
                  ],
                ),
              ),
              // info card
              if (_selectedMarker != null) _buildInfoCard(_selectedMarker!),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _filterButton("Hidden Gems", 'gem', active: _activeFilter == 'gem', onTap: () {
              setState(() => _activeFilter = _activeFilter == 'gem' ? 'all' : 'gem');
            }),
            const SizedBox(width: 12),
            _filterButton("Hotspots", 'hotspot', active: _activeFilter == 'hotspot', onTap: () {
              setState(() => _activeFilter = _activeFilter == 'hotspot' ? 'all' : 'hotspot');
            }),
          ],
        ),
      ],
    );
  }

  Widget _zoomButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Icon(icon, size: 18, color: Colors.black87),
    );
  }

  Widget _filterButton(String label, String key, {required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF96446) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? Colors.transparent : Colors.grey.shade300),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              key == 'hotspot' ? Icons.local_fire_department : Icons.diamond,
              size: 16,
              color: active ? Colors.white : Colors.orange,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> marker) {
    return Positioned(
      left: 60,
      top: 140,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(marker['category'] == 'hotspot' ? Icons.local_fire_department : Icons.diamond,
                    color: const Color(0xFFF96446)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    marker['label'],
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedMarker = null),
                  child: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Premier diving and snorkeling spot",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF96446),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.volume_up, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text("Listen to narration", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              marker['category'] == 'hotspot' ? "Popular Hotspot" : "Hidden Gem",
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search locations...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, size: 18),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}