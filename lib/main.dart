import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ADDED
import 'dart:io'; // ADDED

// Import your separated files
import 'models/bid_model.dart';
import 'services/notification_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_bid_screen.dart';

void main() async {
  // Ensure bindings are initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Offline Database (Hive)
  await Hive.initFlutter();
  Hive.registerAdapter(RequirementAdapter());
  Hive.registerAdapter(BidAdapter());
  await Hive.openBox<Bid>('bidsBox');

  // 2. Initialize Background/Local Notifications
  await NotificationService.init();

  // 3. Request permissions for Android 13+ (Notifications) & Android 14+ (Alarms)
  await requestNotificationPermissions();

  runApp(const BidTrackerApp());
}

// --- ADDED: NEW FUNCTION TO REQUEST PERMISSIONS ---
Future<void> requestNotificationPermissions() async {
  if (Platform.isAndroid) {
    // We create a temporary instance just to ask for permissions
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      // Asks the user for permission to show standard notifications (Android 13+)
      await androidImplementation.requestNotificationsPermission();

      // Asks the user for permission to schedule exact alarms (Android 14+)
      await androidImplementation.requestExactAlarmsPermission();
    }
  }
}

class BidTrackerApp extends StatelessWidget {
  const BidTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Bid Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/add_bid': (context) => const AddBidScreen(),
      },
    );
  }
}
