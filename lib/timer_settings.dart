import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TimerSettingsPage extends StatefulWidget {
  const TimerSettingsPage({Key? key}) : super(key: key);

  @override
  _TimerSettingsPageState createState() => _TimerSettingsPageState();
}

class _TimerSettingsPageState extends State<TimerSettingsPage> {
  late Box timerBox;

  @override
  void initState() {
    super.initState();
    timerBox = Hive.box('timer_settings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Enable Drinks Timer (15 min)'),
            value: timerBox.get('enable_drinks', defaultValue: true),
            onChanged: (val) {
              setState(() {
                timerBox.put('enable_drinks', val);
              });
            },
          ),
          SwitchListTile(
            title: const Text('Enable All Day Dining Timer (90 min)'),
            value: timerBox.get('enable_all_day', defaultValue: true),
            onChanged: (val) {
              setState(() {
                timerBox.put('enable_all_day', val);
              });
            },
          ),
          SwitchListTile(
            title: const Text('Enable All Season Dining Timer (4 hours)'),
            value: timerBox.get('enable_all_season', defaultValue: true),
            onChanged: (val) {
              setState(() {
                timerBox.put('enable_all_season', val);
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Show persistent notification'),
            subtitle: const Text('Shows a countdown in your notifications while the timer is running'),
            value: timerBox.get('enable_persistent_notification', defaultValue: true),
            onChanged: (val) {
              setState(() {
                timerBox.put('enable_persistent_notification', val);
              });
            },
          ),
        ],
      ),
    );
  }
}
