import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapPage extends StatelessWidget {
  final VoidCallback onNavigateHome;
  const MapPage({super.key, required this.onNavigateHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
            onPressed: onNavigateHome,
          ),
        ),
        title: const Text(
          "Map Explorer",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: const _MapView(),
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView();
  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  GoogleMapController? _controller;
  LatLng? _currentPosition;
  List<Map<String, dynamic>> _allPlacesData = []; 
  Set<Marker> _displayedMarkers = {};
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled, don't continue
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try requesting permissions again 
      // or show a UI message to the user.
      return Future.error('Location permissions are denied');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately. 
    return Future.error('Location permissions are permanently denied, we cannot request permissions.');
  } 

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  try {
    Position position = await Geolocator.getCurrentPosition();
    LatLng pos = LatLng(position.latitude, position.longitude);
    if (mounted) {
      setState(() => _currentPosition = pos);
      _fetchPlaces(pos);
    }
  } catch (e) {
    debugPrint("Error getting location: $e");
  }
}
  // --- SEARCH SUGGESTIONS LOGIC ---
  Future<List<Map<String, dynamic>>> _getSuggestions(String query) async {
    if (query.isEmpty) return [];
    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? "";
    final url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey&location=${_currentPosition?.latitude},${_currentPosition?.longitude}&radius=10000";
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List predictions = json.decode(response.body)['predictions'];
      return predictions.map((p) => {
        'description': p['description'],
        'place_id': p['place_id']
      }).toList();
    }
    return [];
  }

  Future<void> _handleSelection(Map<String, dynamic> suggestion) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? "";
    final detailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=${suggestion['place_id']}&key=$apiKey";
    
    final response = await http.get(Uri.parse(detailsUrl));
    if (response.statusCode == 200) {
      final result = json.decode(response.body)['result'];
      final lat = result['geometry']['location']['lat'];
      final lng = result['geometry']['location']['lng'];
      final String name = result['name'] ?? suggestion['description'];
      LatLng target = LatLng(lat, lng);

      _controller?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
      _fetchPlaces(target);
      _showNavigationPrompt(name, lat, lng);
    }
  }

  void _showNavigationPrompt(String name, double lat, double lng) {
    String selectedMode = 'd'; // Default: driving

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF96446).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Color(0xFFF96446),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Navigate to",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              
              // NEW: Travel Mode Selector Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _modeIcon(setModalState, Icons.directions_car, 'd', selectedMode, (m) => selectedMode = m),
                  _modeIcon(setModalState, Icons.directions_walk, 'w', selectedMode, (m) => selectedMode = m),
                  _modeIcon(setModalState, Icons.directions_bus, 't', selectedMode, (m) => selectedMode = m),
                ],
              ),
              
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF96446), Color(0xFFFF7E5F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF96446).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _launchNavigation(lat, lng, selectedMode);
                        },
                        child: const Text(
                          "Navigate",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for mode selection icons
  Widget _modeIcon(StateSetter setState, IconData icon, String modeValue, String current, Function(String) onSelect) {
    bool isSelected = modeValue == current;
    return GestureDetector(
      onTap: () => setState(() => onSelect(modeValue)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFF96446), Color(0xFFFF7E5F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF96446).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.black54,
          size: 28,
        ),
      ),
    );
  }

  Future<void> _fetchPlaces(LatLng pos) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? "";
    final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${pos.latitude},${pos.longitude}&radius=5000&type=tourist_attraction&key=$apiKey';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List results = json.decode(response.body)['results'];
      _allPlacesData = results.where((p) => (p['rating'] ?? 0) >= 4.0).cast<Map<String, dynamic>>().toList();
      _applyFilter(_activeFilter);
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      Set<Marker> newMarkers = {};
      for (var p in _allPlacesData) {
        double rating = (p['rating'] ?? 0).toDouble();
        bool isHotspot = rating >= 4.5;
        String category = isHotspot ? 'hotspot' : 'gem';
        if (filter == 'all' || filter == category) {
          newMarkers.add(Marker(
            markerId: MarkerId(p['place_id']),
            position: LatLng(p['geometry']['location']['lat'], p['geometry']['location']['lng']),
            icon: BitmapDescriptor.defaultMarkerWithHue(isHotspot ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueCyan),
            onTap: () => _showDetail(p, isHotspot),
          ));
        }
      }
      _displayedMarkers = newMarkers;
    });
  }

  void _showDetail(dynamic p, bool isHotspot) {
    String selectedMode = 'd'; // Default: driving

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                p['name'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isHotspot
                      ? const Color(0xFFF96446).withOpacity(0.1)
                      : Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isHotspot ? "🔥 Hotspot" : "💎 Hidden Gem",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isHotspot ? const Color(0xFFF96446) : Colors.cyan.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "${p['rating']}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Travel Mode Selector Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _modeIcon(setModalState, Icons.directions_car, 'd', selectedMode, (m) => selectedMode = m),
                  _modeIcon(setModalState, Icons.directions_walk, 'w', selectedMode, (m) => selectedMode = m),
                  _modeIcon(setModalState, Icons.directions_bus, 't', selectedMode, (m) => selectedMode = m),
                ],
              ),
              
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF96446), Color(0xFFFF7E5F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF96446).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _launchNavigation(
                      p['geometry']['location']['lat'],
                      p['geometry']['location']['lng'],
                      selectedMode,
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Navigate",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchNavigation(double lat, double lng, String mode) async {
    // For transit mode, show the directions page with transport options
    if (mode == 't') {
      final transitUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=transit';
      await launchUrl(Uri.parse(transitUrl), mode: LaunchMode.externalApplication);
      return;
    }
    
    // For driving and walking, use the native navigation
    // Mode parameters: d=driving, w=walking
    final url = 'google.navigation:q=$lat,$lng&mode=$mode';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _currentPosition == null 
          ? const Center(child: CircularProgressIndicator()) 
          : GoogleMap(
              initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 14),
              onMapCreated: (c) => _controller = c,
              markers: _displayedMarkers,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              padding: const EdgeInsets.only(top: 180, bottom: 20),
            ),
        
        // --- AUTOCOMPLETE SEARCH BAR ---
        Positioned(
          top: 20,
          left: 16,
          right: 16,
          child: Autocomplete<Map<String, dynamic>>(
            displayStringForOption: (option) => option['description'],
            optionsBuilder: (TextEditingValue textEditingValue) async {
              return await _getSuggestions(textEditingValue.text);
            },
            onSelected: _handleSelection,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search destinations...",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 8,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // --- FILTER ROW ---
        Positioned(
          top: 96,
          left: 16,
          right: 16,
          child: _FilterRowUI(activeFilter: _activeFilter, onFilter: _applyFilter),
        ),
      ],
    );
  }
}

class _FilterRowUI extends StatelessWidget {
  final String activeFilter;
  final Function(String) onFilter;
  const _FilterRowUI({required this.activeFilter, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildChip("All", 'all')),
        const SizedBox(width: 10),
        Expanded(child: _buildChip("Gems 💎", 'gem')),
        const SizedBox(width: 10),
        Expanded(child: _buildChip("Hotspots 🔥", 'hotspot')),
      ],
    );
  }

  Widget _buildChip(String label, String key) {
    bool active = activeFilter == key;
    return GestureDetector(
      onTap: () => onFilter(key),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFFF96446), Color(0xFFFF7E5F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? const Color(0xFFF96446).withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              blurRadius: active ? 12 : 8,
              offset: Offset(0, active ? 4 : 2),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}