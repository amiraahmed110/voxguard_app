import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/colors.dart'; 
import 'location_sheets.dart'; 
import 'manage_safety_places.dart';
import '../../custom_widgets/custom_button.dart';

class FullMapScreen extends StatefulWidget {
  const FullMapScreen({super.key});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {}; 
  
  Marker? _searchMarker; 
  Marker? _tempMarkedMarker; 
  
  Map<String, LatLng> _safePlaces = {};
  List<Map<String, dynamic>> _recentPlaces = [];

  bool _isPickingLocation = false;
  bool _isSelectingZoneLocation = false; 
  String? _pendingPlaceType;

  String _suggestedName = "Searching nearby...";
  String _suggestedDist = "";
  LatLng? _suggestedLocation;
  IconData _suggestionIcon = Icons.location_on;

  @override
  void initState() {
    super.initState();
    _loadData();
    _determinePosition();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final placesJson = prefs.getString('safePlaces');
    if (placesJson != null) {
      final Map<String, dynamic> data = json.decode(placesJson);
      setState(() {
        _safePlaces = data.map((key, value) => MapEntry(key, LatLng(value['lat'], value['lng'])));
      });
    }

    final recentsJson = prefs.getString('recentPlaces');
    if (recentsJson != null) {
      setState(() => _recentPlaces = List<Map<String, dynamic>>.from(json.decode(recentsJson)));
    }

    final circlesJson = prefs.getString('saved_zones');
    if (circlesJson != null) {
      final List<dynamic> decodedCircles = json.decode(circlesJson);
      setState(() {
        _circles = decodedCircles.map((c) => Circle(
          circleId: CircleId(c['id']),
          center: LatLng(c['lat'], c['lng']),
          radius: c['radius'],
          fillColor: c['type'] == 'safe' ? Colors.blue.withOpacity(0.15) : Colors.red.withOpacity(0.15),
          strokeColor: c['type'] == 'safe' ? Colors.blue : Colors.red,
          strokeWidth: 1,
        )).toSet();
      });
    }
    _refreshMarkers();
  }

  void _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('safePlaces', json.encode(_safePlaces.map((k, v) => MapEntry(k, {'lat': v.latitude, 'lng': v.longitude}))));
  }

  void _saveCirclesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> circlesList = _circles.map((c) => {
      'id': c.circleId.value,
      'lat': c.center.latitude,
      'lng': c.center.longitude,
      'radius': c.radius,
      'type': c.strokeColor == Colors.blue ? 'safe' : 'red',
    }).toList();
    prefs.setString('saved_zones', json.encode(circlesList));
  }

  Future<BitmapDescriptor> _getBitmapFromIcon(IconData iconData, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(fontSize: 90.0, fontFamily: iconData.fontFamily, color: color),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(0, 0));

    final ui.Image image = await pictureRecorder.endRecording().toImage(90, 90);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  void _refreshMarkers() async {
    Set<Marker> newMarkers = {};
    for (var entry in _safePlaces.entries) {
      IconData iconData = Icons.shield_rounded;
      if (entry.key == "Home") iconData = Icons.home_rounded;
      if (entry.key == "Work") iconData = Icons.work_rounded;

      final iconImage = await _getBitmapFromIcon(iconData, Colors.blue);
      newMarkers.add(Marker(
        markerId: MarkerId(entry.key),
        position: entry.value,
        icon: iconImage,
      ));
    }
    if (_searchMarker != null) newMarkers.add(_searchMarker!);
    if (_tempMarkedMarker != null) newMarkers.add(_tempMarkedMarker!);
    setState(() => _markers = newMarkers);
  }

  // --- جلب العنوان من الإحداثيات ---
  Future<String> _getAddressFromLatLng(LatLng position) async {
    final url = "https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18";
    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'VoxGuard'});
      final data = json.decode(response.body);
      return data['name'] ?? data['address']['road'] ?? data['address']['suburb'] ?? "Selected Location";
    } catch (e) {
      return "Selected Location";
    }
  }

  // --- البحث والموقع ---
  Future<void> _determinePosition() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => _currentPosition = LatLng(position.latitude, position.longitude));
    _getSmartSuggestion(position.latitude, position.longitude);
  }

  Future<void> _handleSearch(String input) async {
    if (input.isEmpty) return;
    final url = "https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(input)}&format=json&limit=1";
    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'VoxGuard'});
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        final pos = LatLng(double.parse(data[0]['lat']), double.parse(data[0]['lon']));
        setState(() {
          _searchMarker = Marker(
            markerId: const MarkerId("search_result"),
            position: pos,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          );
        });
        _moveTo(pos); 
        _addToRecents(input, data[0]['display_name'], pos.latitude, pos.longitude);
        _refreshMarkers();
        _searchController.clear();
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  void _addToRecents(String name, String addr, double lat, double lng) async {
    setState(() {
      _recentPlaces.removeWhere((item) => item['name'] == name);
      _recentPlaces.insert(0, {'name': name, 'address': addr, 'lat': lat, 'lng': lng});
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('recentPlaces', json.encode(_recentPlaces));
  }

  void _deleteRecent(int index) async {
    setState(() => _recentPlaces.removeAt(index));
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('recentPlaces', json.encode(_recentPlaces));
  }

  // --- التفاعل مع الخريطة ---
  void _onMapTap(LatLng position) async {
    if (_isSelectingZoneLocation) {
      setState(() => _isSelectingZoneLocation = false); 
      
      String placeName = await _getAddressFromLatLng(position);

      if (!mounted) return;
      LocationSheets.showMarkLocationOptions(
        context, 
        position, 
        placeName, 
        (radius, type) {
          _addNewCircle(position, radius, type);
        }
      );
      _sheetController.animateTo(0.15, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    } 
    else if (_isPickingLocation) {
      if (_pendingPlaceType == "Home" || _pendingPlaceType == "Work") {
        _savePlaceAndRefresh(_pendingPlaceType!, position);
      } else {
        _showNameInputDialog(position);
      }
    }
  }

  void _addNewCircle(LatLng pos, double radius, String type) {
    setState(() {
      _circles.add(
        Circle(
          circleId: CircleId("zone_${DateTime.now().millisecondsSinceEpoch}"),
          center: pos,
          radius: radius,
          fillColor: type == "safe" 
              ? Colors.blue.withOpacity(0.15) 
              : Colors.red.withOpacity(0.15),
          strokeColor: type == "safe" ? Colors.blue : Colors.red,
          strokeWidth: 1,
        ),
      );
    });
    _saveCirclesToPrefs();
  }

  void _savePlaceAndRefresh(String name, LatLng position) {
    setState(() {
      _safePlaces[name] = position;
      _isPickingLocation = false;
      _pendingPlaceType = null;
    });
    _saveToPrefs();
    _refreshMarkers();
  }

  void _showNameInputDialog(LatLng position) {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Safe Place"),
        content: TextField(controller: nameController, decoration: const InputDecoration(hintText: "Enter name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                _savePlaceAndRefresh(nameController.text, position);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _moveTo(LatLng pos) async {
    final c = await _controller.future;
c.animateCamera(
  CameraUpdate.newCameraPosition(
    CameraPosition(target: pos, zoom: 17),
  ),
);       }

  // --- بناء الواجهة ---
  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentPosition!, zoom: 15),
            myLocationEnabled: true,
            markers: _markers,
            circles: _circles, 
            onMapCreated: (c) => _controller.complete(c),
            onTap: _onMapTap,
          ),
          
          if (_isSelectingZoneLocation || _isPickingLocation)
            Positioned(
              top: 100, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: AppColors.primaryPurple, borderRadius: BorderRadius.circular(15)),
                child: Text(
                  "📍 Tap on map to set ${_isSelectingZoneLocation ? 'Zone' : (_pendingPlaceType ?? 'Place')}", 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),

          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.15,
            minChildSize: 0.15,
            maxChildSize: 0.75,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: const BorderRadius.vertical(top: Radius.circular(35))),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildHandle(),
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    _buildSectionHeader("Safe Suggestions"),
                    _buildSuggestionCard(),
                    const SizedBox(height: 25),
                    _buildSectionHeader("Safe Places", showArrow: true, onTap: () => _navToManagePlaces()),
                    _buildSafePlacesRow(),
                    const SizedBox(height: 25),
                    _buildSectionHeader("Recents"),
                    ..._recentPlaces.asMap().entries.map((entry) => _buildRecentTile(entry.key, entry.value)),
                    const SizedBox(height: 30),
                    CustomButton(text: "Share My Location", onPressed: () {}),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: _isSelectingZoneLocation ? "Cancel Selection" : "Mark My Location", 
                      onPressed: () {
                        setState(() {
                          _isSelectingZoneLocation = !_isSelectingZoneLocation;
                        });
                        if (_isSelectingZoneLocation) {
                          _sheetController.animateTo(0.15, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      }
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Widgets ---
  Widget _buildRecentTile(int index, Map p) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.orange.withOpacity(0.1),
        child: const Icon(Icons.place_rounded, color: Colors.orange, size: 20),
      ),
      title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(p['address'] ?? "No address", style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _deleteRecent(index)),
      onTap: () => _moveTo(LatLng(p['lat'], p['lng'])),
    );
  }

  Widget _buildSafePlacesRow() {
    return Row(
      children: [
        _buildSafeCircle("Home", Icons.home_rounded, "Home"),
        const SizedBox(width: 20),
        _buildSafeCircle("Work", Icons.work_rounded, "Work"),
        const SizedBox(width: 20),
        _buildSafeCircle("Add", Icons.add, "Other"),
      ],
    );
  }

  Widget _buildSafeCircle(String label, IconData icon, String key) {
    bool exists = _safePlaces.containsKey(key);
    return GestureDetector(
    onTap: () async {
  if (exists) {
    await _moveTo(_safePlaces[key]!);
  } else {
    setState(() {
      _isPickingLocation = true;
      _pendingPlaceType = key;
    });
  }
},
      child: Column(children: [
        Container(
          width: 65, height: 65,
          decoration: BoxDecoration(
            color: exists ? const Color(0xFFE1F0FF) : Colors.grey[100],
            shape: BoxShape.circle,
            border: exists ? Border.all(color: Colors.blue, width: 2) : null,
          ),
          child: Icon(icon, color: exists ? Colors.blue : Colors.grey, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        Text(exists ? "Saved" : "Add", style: TextStyle(fontSize: 12, color: exists ? Colors.green : Colors.blue)),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        const Icon(CupertinoIcons.search, color: Colors.grey),
        Expanded(child: TextField(controller: _searchController, onSubmitted: _handleSearch, decoration: const InputDecoration(hintText: "Search Maps", border: InputBorder.none))),
        const Icon(CupertinoIcons.mic_fill, color: Colors.grey),
      ]),
    );
  }

  Widget _buildSectionHeader(String title, {bool showArrow = false, VoidCallback? onTap}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      if (showArrow) IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey), onPressed: onTap),
    ]);
  }

  Widget _buildHandle() => Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))));

  Widget _buildSuggestionCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.blue, child: Icon(_suggestionIcon, color: Colors.white)),
        title: Text(_suggestedName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_suggestedDist),
        onTap: () => _suggestedLocation != null ? _moveTo(_suggestedLocation!) : null,
      ),
    );
  }

  void _navToManagePlaces() {
     Navigator.push(context, MaterialPageRoute(builder: (context) => ManagePlacesScreen(
      places: _safePlaces,
      onDelete: (key) { setState(() => _safePlaces.remove(key)); _saveToPrefs(); _refreshMarkers(); },
      onEdit: (oldKey, newKey) {
        setState(() { final pos = _safePlaces.remove(oldKey); if (pos != null) _safePlaces[newKey] = pos; });
        _saveToPrefs(); _refreshMarkers();
      },
      onAdd: () => setState(() => _isPickingLocation = true), 
      onPlaceSelected: (LatLng p1, String p2) {  },
    )));
  }

  Future<void> _getSmartSuggestion(double lat, double lon) async {
    final url = "https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent('[out:json];(node["amenity"~"pharmacy|hospital|police|clinic"](around:1000,$lat,$lon););out center;')}";
    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      if (data['elements'] != null && data['elements'].isNotEmpty) {
        var nearest = data['elements'][0];
        setState(() {
          _suggestedName = nearest['tags']['name'] ?? "Nearby Safe Point";
          _suggestedLocation = LatLng(nearest['lat'] ?? nearest['center']['lat'], nearest['lon'] ?? nearest['center']['lon']);
          _suggestedDist = "Safe location detected nearby";
          _suggestionIcon = Icons.health_and_safety;
        });
      } 
    } catch (e) { debugPrint(e.toString()); }
  }
}