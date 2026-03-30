import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../trust_contacts/add_contact_screen.dart';
import '../../custom_widgets/custom_button.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  List<dynamic> contacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      var response = await Dio().get(
        "http://192.168.1.191:8000/api/trusted-contacts",
        options: Options(
          headers: {
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
        ),
      );

      if (mounted) {
        setState(() {
         
          if (response.data is Map && response.data['contacts'] != null) {
            contacts = response.data['contacts'];
          } else {
            contacts = [];
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8E9EFE), Color(0xFFE040FB)],
              ),
            ),
          ),
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : contacts.isEmpty
                                ? const Center(child: Text("No contacts added yet"))
                                : ListView.builder(
                                    itemCount: contacts.length,
                                    itemBuilder: (context, index) => _buildContactCard(contacts[index]),
                                  ),
                      ),
                      CustomButton(
                        text: "Add new",
                        onPressed: () async {
                          bool? refresh = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddContactScreen()),
                          );
                          if (refresh == true) _fetchContacts();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 140,
      padding: const EdgeInsets.only(top: 60, left: 16),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const Text('Trusted Contacts', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

 Widget _buildContactCard(dynamic contact) {
  String imageUrl = contact['image'] ?? "";
  String name = "${contact['first_name'] ?? ''} ${contact['last_name'] ?? ''}".trim();
  if (name.isEmpty) name = contact['name'] ?? "No Name";
  
  String status = (contact['status'] ?? "offline").toLowerCase();
  
  Color statusColor = Colors.grey;
  if (status == "online") statusColor = Colors.green;
  if (status == "nearby") statusColor = Colors.purple;

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade300), 
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [

        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),

            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              Text(
                contact['relation'] ?? "Relative",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              Text(
                contact['phone'] ?? "No Phone",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        Text(
          status[0].toUpperCase() + status.substring(1),
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}

Widget _buildPlaceholder() {
  return Container(
    width: 60,
    height: 60,
    color: Colors.grey[200],
    child: const Icon(Icons.person, color: Colors.grey),
  );
}
}