import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'restaruantviewer.dart'; // Import the restaurant viewer page

class RestaurantsPage extends StatelessWidget {
  const RestaurantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: 
            Text('Uh oh something happened: ${snapshot.error}'));

          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Couldnt find any restraurants, If you see this we have switched our backend over, update your app'));
          }

          final restaurants = snapshot.data!.docs;

          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              final data = restaurant.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  leading: const Icon(Icons.restaurant), // Icon for each item
                  title: Text(data['Name'] ?? 'Uhh, Whats this again i forgot'), // Display restaurant name
                  subtitle: Text(data['Description'] ?? 'Uhh, Whats this again i forgot'), // Display description
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantViewer(
                          restaurantId: restaurant.id, // Pass the restaurant ID to the viewer
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}