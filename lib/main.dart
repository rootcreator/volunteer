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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  String? token = await messaging.getToken();
  print("FCM Token: $token");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    NotificationService.showLocalNotification(message);
  });

  // Optional: handle background/terminated notifications
  setupFCMHandlers();

  runApp(const VolunteerApp());
}

void setupFCMHandlers() {
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    print("Notification opened in background");
  });

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      print("Notification opened from terminated");
    }
  });
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
          '/adminEvents': (_) => const AdminEventListScreen(),
          '/addEvent': (_) => const CreateEventScreen(),
          '/calendar': (_) => const CalendarScreen(),
          '/eventDetails': (_) => const VolunteerEventDetailScreen(eventId: ''),
          '/volunteerEvents': (_) => const VolunteerEventsScreen(),
          '/analytics': (_) => const VolunteerAnalyticsScreen()
        }

    );
  }
}
