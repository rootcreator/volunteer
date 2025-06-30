import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/admin/admin_events_screen.dart';
import 'screens/admin/create_event_screen.dart';
import 'screens/auth_gate.dart';
import 'screens/calendar_screen.dart';
import 'screens/home_screen.dart';
import 'screens/volunteer/volunteer_analytics_screen.dart';
import 'screens/volunteer/volunteer_event_detail_screen.dart';
import 'screens/volunteer/volunteer_events_screen.dart';
import 'services/notification_service.dart';

import 'firebase_options.dart';





void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    NotificationService.showLocalNotification(message);
  });

  runApp(const VolunteerApp());
}

class VolunteerApp extends StatelessWidget {
  const VolunteerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volunteer Coordination',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const AuthGate(),

      // Optional: add named routes if you use them
      routes: {
        '/login': (_) => const AuthGate(),
        '/home': (_) => const HomeScreen(),
        '/admin events': (_) => const AdminEventListScreen(),
        '/add event': (_) => const CreateEventScreen(),
        '/calendar': (_) => const CalendarScreen(),
        '/event details': (_) => const VolunteerEventDetailScreen(eventId: '',),
        '/events for volunteers': (_) => const VolunteerEventsScreen(),
        '/analytics': (_) => const VolunteerAnalyticsScreen()

      },
    );
  }
}
