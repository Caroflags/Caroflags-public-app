import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'passes.dart';
import 'package:http/http.dart' as http;
import 'map.dart';
import 'restrauantslist.dart';
import 'randomtext.dart';
import 'testernotice.dart';
import 'testpage.dart';
import 'park_status.dart';
import 'services/ota_service.dart';

Future<String?> getUsername() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  DocumentSnapshot userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (userDoc.exists) {
    return userDoc.get('username') as String?;
  }
  return null;
}

Future<String?> getEmail() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  DocumentSnapshot userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (userDoc.exists) {
    return userDoc.get('email') as String?;
  }
  return null;
}

class RealHome extends StatefulWidget {
  const RealHome({Key? key}) : super(key: key);

  @override
  _RealHomeState createState() => _RealHomeState();
}

class _RealHomeState extends State<RealHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OtaService.checkForUpdates(context);
    });
  }

  int _selectedIndex = 0;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _items = [
    {
      'title': 'Wallet',
      'subtitle': 'This is where all of your passes go',
      'page': PassesScreen(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      ),
    },
    {'title': 'Map', 'subtitle': 'The map for carowinds', 'page': MapScreen()},
    {
      'title': 'Restaurants',
      'subtitle': 'A list of the restaurants',
      'page': RestaurantsPage(),
    },
    {
      'title': 'Testing',
      'subtitle': 'A page for testing features',
      'page': const TestPage(),
    },
  ];
  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  void _openDetail(Map<String, dynamic> item) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => item['page']));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((it) {
      final q = _searchQuery.toLowerCase();
      return it['title']!.toLowerCase().contains(q) ||
          it['subtitle']!.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming Soon!')));
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              FutureBuilder<List<String?>>(
                future: Future.wait([getUsername(), getEmail()]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Loading...'),
                      subtitle: Text(''),
                    );
                  }
                  if (snapshot.hasError) {
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Error loading user'),
                      subtitle: Text(''),
                    );
                  }
                  final username = snapshot.data?[0] ?? 'Who are you?';
                  final email = snapshot.data?[1] ?? 'Jimbob@googlemail.com';
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(username),
                    subtitle: Text(email),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                selected: _selectedIndex == 0,
                onTap: () {
                  Navigator.pop(context);
                  _onNavTap(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Favorites'),
                selected: _selectedIndex == 1,
                onTap: () {
                  Navigator.pop(context);
                  _onNavTap(1);
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout ):'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _selectedIndex == 0
            ? ListView(
                children: [
                  FutureBuilder<http.Response>(
                    future: http.get(
                      Uri.parse('https://api.caroflags.xyz/health'),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text("Checking if the api isn't dead...");
                      } else if (snapshot.hasError) {
                        return const Text(
                          'Error fetching API status. You prolly have no wifi or something. or the servers are screwed',
                        );
                      } else if (snapshot.hasData &&
                          snapshot.data!.statusCode == 200) {
                        return const SizedBox.shrink();
                      } else {
                        return Text(
                          'The api is down. You will still be able to login and view your passes (Thanks google), But anything that goes through the api will fail to load. (Reviews, countdowns, etc). Error code: ${snapshot.data?.statusCode ?? 'good lord we dont even know what error code it is'}',
                        );
                      }
                    },
                  ),

                  Text(randomStatement),
                  const ParkStatus(),
                  const SizedBox(height: 8),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3 / 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return GestureDetector(
                        onTap: () => _openDetail(item),
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        child: Text(
                                          (item['title'] != null &&
                                                  item['title']!.isNotEmpty)
                                              ? item['title']![0]
                                              : '?',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['title']!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  item['subtitle']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              )
            : Center(
                child: Text(
                  'This is unfinished',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}

class _DetailPage extends StatelessWidget {
  final Map<String, String> item;
  const _DetailPage({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item['title']!)),

      body: Center(
        child: Column(
          children: [
            FutureBuilder<http.Response>(
              future: http.get(Uri.parse('https://api.caroflags.xyz/health')),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text('Error fetching API status.');
                } else if (snapshot.hasData &&
                    snapshot.data!.statusCode == 200) {
                  return const SizedBox.shrink();
                } else {
                  return Text(
                    'Uh oh! The servers seem to be having some issues right now. Our servers restart every month and that takes about 5 minutes. If it doesn\'t work after 5 minutes, we may acutally be having some issues. Error code: ${snapshot.data?.statusCode ?? 'good lord we dont even know what error code it is'}',
                  );
                }
              },
            ),

            Text('$randomStatement'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        // Sign out the user when the button is pressed
                        await FirebaseAuth.instance.signOut();
                        // Navigate back to the login page
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text('Logout ):'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to the passes page
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PassesScreen(
                              userId:
                                  FirebaseAuth.instance.currentUser?.uid ?? '',
                            ),
                          ),
                        );
                      },
                      child: const Text('Wallet'),
                    ),

                    ElevatedButton(
                      onPressed: () {
                        // Navigate to the passes page
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RestaurantsPage(),
                          ),
                        );
                      },
                      child: const Text('Restaurants'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to the timers page
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => MapScreen()),
                        );
                      },
                      child: const Text('Map'),
                    ),

                    ElevatedButton(
                      onPressed: () {
                        // Navigate to the test page
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TestPage(),
                          ),
                        );
                      },
                      child: const Text('Testing'),
                    ),

                    ElevatedButton(
                      onPressed: () {
                        // Show the tester notice
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Tester Notice'),
                              content: TesterNotice(),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('Notice For Testers'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
