import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../services/inquiry_service.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final _messageController = TextEditingController(text: "Hi, I am interested in this property.");
  bool _isSending = false;

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Contact Owner"),
        content: TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Message",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: _isSending ? null : _sendInquiry,
            child: _isSending
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Send"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInquiry() async {
    setState(() => _isSending = true);

    final result = await InquiryService.sendInquiry(
      propertyId: widget.property.id,
      message: _messageController.text.trim(),
    );

    setState(() => _isSending = false);

    if (mounted) Navigator.pop(context); // dialog band karo

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result["success"] == true
                ? "Inquiry sent successfully!"
                : "Failed to send inquiry. Login check karo.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    return Scaffold(
      appBar: AppBar(title: Text(property.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (property.media.isNotEmpty)
              SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: property.media.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      property.media[index].file,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  },
                ),
              )
            else
              Container(
                height: 220,
                color: Colors.grey[300],
                child: const Icon(Icons.home, size: 80, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹${property.price}",
                    style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${property.locality}, ${property.city}"),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Chip(label: Text(property.propertyType)),
                  const SizedBox(height: 16),
                  const Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(property.description, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 16),
                  const Text("Listed by", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(property.ownerName),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.message),
                      label: const Text("Contact Owner"),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: _showContactDialog,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}