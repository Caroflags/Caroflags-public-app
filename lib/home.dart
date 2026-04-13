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
import 'settings.dart';

class HealthCheckWidget extends StatefulWidget {
  const HealthCheckWidget({Key? key}) : super(key: key);

  @override
  State<HealthCheckWidget> createState() => _HealthCheckWidgetState();
}

class _HealthCheckWidgetState extends State<HealthCheckWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<http.Response>(
      future: http.get(Uri.parse('https://api.caroflags.xyz/health')),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Text('Error fetching API status.');
        } else if (snapshot.hasData && snapshot.data!.statusCode == 200) {
          return const SizedBox.shrink();
        } else {
          return Text(
            'Uh oh! The servers seem to be having some issues right now. Error code: ${snapshot.data?.statusCode ?? 'good lord we dont even know what error code it is'}',
          );
        }
      },
    );
  }
}

Future<Map<String, String?>> getUserData() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return {'username': null, 'email': null};

  DocumentSnapshot userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (userDoc.exists) {
    return {
      'username': userDoc.get('username') as String?,
      'email': userDoc.get('email') as String?,
    };
  }
  return {'username': null, 'email': null};
}

class RealHome extends StatefulWidget {
  const RealHome({Key? key}) : super(key: key);

  @override
  _RealHomeState createState() => _RealHomeState();
}

class _RealHomeState extends State<RealHome> {
  Future<http.Response>? _apiHealthFuture;

  @override
  void initState() {
    super.initState();
    _apiHealthFuture = http.get(Uri.parse('https://api.caroflags.xyz/health'));
  }

  int _selectedIndex = 0;
  String _searchQuery = '';
  int _homeTapCount = 0; // Tracks consecutive taps on the drawer's Home button

  final List<Map<String, dynamic>> _items = [
    {
      'title': 'Wallet',
      'subtitle': 'This is where all of your passes go',
      'icon': Icons.wallet,
      'page': PassesScreen(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      ),
    },
    {
      'title': 'Map',
      'subtitle': 'The map for Carowinds',
      'icon': Icons.map,
      'page': MapScreen(),
    },
    {
      'title': 'Restaurants',
      'subtitle': 'A list of the restaurants',
      'icon': Icons.restaurant,
      'page': RestaurantsPage(),
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
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              FutureBuilder<Map<String, String?>>(
                future: getUserData(),
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
                  final username = snapshot.data?['username'] ?? 'Who are you?';
                  final email =
                      snapshot.data?['email'] ?? 'Jimbob@googlemail.com';
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
                  if (_selectedIndex == 0) {
                    _homeTapCount++;
                    if (_homeTapCount >= 10) {
                      _homeTapCount = 0; // Reset counter
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TestPage()),
                      );
                    }
                  } else {
                    _homeTapCount = 0; // Reset if coming from another tab
                    _onNavTap(0);
                  }
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout ):'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
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
                    future: _apiHealthFuture,
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
                  const HealthCheckWidget(),
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
                                      Icon(item['icon']),
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
                    'Uh oh! The servers seem to be having some issues right now. Error code: ${snapshot.data?.statusCode ?? 'good lord we dont even know what error code it is'}',
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
