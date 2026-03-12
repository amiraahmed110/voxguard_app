import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; 

class ManagePlacesScreen extends StatefulWidget {
  final Map<String, LatLng> places;
  final Function(String) onDelete;
  final Function(String, String) onEdit;
  final VoidCallback onAdd;
  final Function(LatLng, String) onPlaceSelected;

  const ManagePlacesScreen({
    super.key,
    required this.places,
    required this.onDelete,
    required this.onEdit,
    required this.onAdd,
    required this.onPlaceSelected,
  });

  @override
  State<ManagePlacesScreen> createState() => _ManagePlacesScreenState();
}

class _ManagePlacesScreenState extends State<ManagePlacesScreen> {
  
  // Function to get a "Readable" address in English
  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        String street = place.street ?? "";
        String subLocality = place.subLocality ?? ""; // District/Neighborhood
        String locality = place.locality ?? "";       // City

        // Return a clean format: "District, City" or "Street, City"
        if (subLocality.isNotEmpty) {
          return "$subLocality, $locality";
        } else {
          return "$street, $locality";
        }
      }
    } catch (e) {
      return "Address not available";
    }
    return "Unknown Location";
  }

  void _showEditDialog(String oldName) {
    TextEditingController controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Place Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new name"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                widget.onEdit(oldName, controller.text);
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context))
        ],
      ),
      body: Column(
        children: [
          const Center(child: Icon(Icons.stars, color: Colors.orange, size: 100)),
          const Text("Safe Places", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text("${widget.places.length} places saved", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: widget.places.isEmpty
                  ? const Center(child: Text("No safe places yet."))
                  : ListView.separated(
                      itemCount: widget.places.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1, 
                        thickness: 1, 
                        indent: 25,     // Centered divider
                        endIndent: 25, 
                        color: Colors.grey[100],
                      ),
                      itemBuilder: (context, index) {
                        String key = widget.places.keys.elementAt(index);
                        LatLng position = widget.places.values.elementAt(index);

                        return ListTile(
                          onTap: () {
                            widget.onPlaceSelected(position, key);
                            Navigator.pop(context);
                          },
                          leading: const CircleAvatar(
                              backgroundColor: Colors.pink,
                              child: Icon(Icons.location_on, color: Colors.white, size: 20)),
                          title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: FutureBuilder<String>(
                            future: _getAddressFromLatLng(position),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text("Fetching address...", style: TextStyle(fontSize: 10));
                              }
                              return Text(
                                snapshot.data ?? "No address found",
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 22),
                                onPressed: () => _showEditDialog(key),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                onPressed: () {
                                  widget.onDelete(key);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 35, top: 20),
            child: Center(
              child: _buildActionCircle(Icons.add_box_outlined, () {
                Navigator.pop(context);
                widget.onAdd();
              }),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[300]!, width: 1.5)),
        child: Icon(icon, size: 30, color: Colors.blueAccent),
      ),
    );
  }
}