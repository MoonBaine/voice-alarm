import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

import 'alarm_service.dart';
import 'screens/home_screen.dart';
import 'screens/ring_screen.dart';
import 'storage.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  await Alarm.init();
  await AlarmService.rescheduleAll();
  runApp(const VoiceAlarmApp());
}

class VoiceAlarmApp extends StatefulWidget {
  const VoiceAlarmApp({super.key});

  @override
  State<VoiceAlarmApp> createState() => _VoiceAlarmAppState();
}

class _VoiceAlarmAppState extends State<VoiceAlarmApp> {
  StreamSubscription<AlarmSet>? _sub;
  bool _ringScreenOpen = false;

  @override
  void initState() {
    super.initState();
    // BehaviorSubject: od razu dostajemy aktualny stan, wiec dziala tez
    // gdy aplikacja zostala otwarta przez full-screen intent budzika.
    _sub = Alarm.ringing.listen(_onRinging);
  }

  void _onRinging(AlarmSet set) {
    if (set.alarms.isEmpty || _ringScreenOpen) return;
    final nav = navigatorKey.currentState;
    if (nav == null) {
      // Nawigator jeszcze nie gotowy - sprobuj po pierwszej klatce.
      WidgetsBinding.instance.addPostFrameCallback((_) => _onRinging(set));
      return;
    }
    _ringScreenOpen = true;
    final id = set.alarms.first.id;
    nav
        .push(MaterialPageRoute<void>(builder: (_) => RingScreen(alarmId: id)))
        .whenComplete(() => _ringScreenOpen = false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Alarm',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
