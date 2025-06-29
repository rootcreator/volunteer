import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/auth_gate.dart';
import 'services/notification_service.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        '/home': (_) => const HomeScreen(), etc.
      },
    );
  }
}
