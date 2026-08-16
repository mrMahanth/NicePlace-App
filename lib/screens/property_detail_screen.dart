import 'package:flutter/material.dart';
import '../models/property_model.dart';

class PropertyDetailScreen extends StatelessWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(property.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}