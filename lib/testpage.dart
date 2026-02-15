import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
// this comment is so that github will actually commit

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  List<dynamic> reviews = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testing pages'),
      ),
      body: Column(

        children: [
          const Text('This is a test page. This does not have any real functionality and may get removed later'),
          ElevatedButton(
            onPressed: () {
              // Request notification permissions
              AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
                if (!isAllowed) {
                  AwesomeNotifications().requestPermissionToSendNotifications();
                }
              });

              // Create a notification
              AwesomeNotifications().createNotification(
                content: NotificationContent(
                  id: 1,
                  channelKey: 'basic_channel',
                  title: 'Caroflags',
                  body: 'I think it works',
                ),
                
              );
            },
            
            child: const Text('Show Notification'),
          ),
          const SizedBox(height: 20),
          const Text('Press the button to show a notification.'),

          ElevatedButton(
            onPressed: () async {
              Position position = await Geolocator.getCurrentPosition(locationSettings: LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 100,
              ));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lat: ${position.latitude}, Long: ${position.longitude}')));
            },
              child: Text("Get Location"),
            ),

          ElevatedButton(
            onPressed: () async {
              String? idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
              var url = Uri.parse('https://api.caroflags.xyz/reviews');
              var response = await http.get(
                url,
                headers: {
                  'Authorization': 'Bearer $idToken',
                },
              );

              // Ensure the widget is still mounted before using context or calling setState
              if (!mounted) return;

              if (response.statusCode == 200) {
                var data = jsonDecode(response.body);

                setState(() {
                  reviews = data; // Assuming the API returns a list of reviews
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Request failed with status: ${response.statusCode}.')),
                );
              }
            },
              child: Text("test api"),
              ),
              Expanded(
              child: ListView.builder(
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                var review = reviews[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                  title: Text('Attraction: ${review['attraction']} - ${review['rating'] != null ? 'Rating: ${review['rating']}' : 'No rating available'}'),
                  subtitle: Text('Content: ${review['content'] ?? 'No content available'}'),
                  ),
                );
                },
              ),
              ),

            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Test Dialog'),
                      content: const Text('This is a test dialog.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Test Api calls'),
            ),



        ],
      ),
    );
  }
}
