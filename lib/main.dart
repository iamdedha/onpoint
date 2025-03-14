import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'view/splash_screen.dart'; // Your existing splash screen.
import 'view/home.dart';         // HomeScreen should accept selectedNewsUrl and language.

/// Global navigator key for navigation from notification tap.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Background message handler for Firebase Cloud Messaging.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message received: ${message.messageId}");
}

/// Helper function to retrieve the user's preferred language from SharedPreferences.
Future<String> getPreferredLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  // Returns 'hi' for Hindi, 'en' for English. Defaults to English if not set.
  return prefs.getString('preferred_language') ?? 'en';
}

/// Global instance for local notifications.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Set up local notifications (Android) with proper callback.
Future<void> setupLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      print("Local notification tapped with payload: ${response.payload}");
      if (response.payload != null && response.payload!.isNotEmpty) {
        try {
          final Map<String, dynamic> payloadData = jsonDecode(response.payload!);
          final String newsUrl = payloadData['news_url'] ?? "";
          if (newsUrl.isNotEmpty) {
            final lang = await getPreferredLanguage();
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => HomeScreen(
                  selectedNewsUrl: newsUrl,
                  language: lang,
                ),
              ),
            );
          }
        } catch (e) {
          print("Error parsing payload: $e");
        }
      }
    },
  );
}

/// Displays a custom notification using BigTextStyle to show complete text.
/// The payload includes the news URL.
Future<void> showBigTextNotification(String title, String body, String newsUrl) async {
  final String payloadData = jsonEncode({"news_url": newsUrl});
  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'big_text_channel',
    'Big Text Notifications',
    channelDescription: 'Channel for showing complete text notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    styleInformation: BigTextStyleInformation(
      body,
      contentTitle: title,
      htmlFormatContent: true,
      htmlFormatContentTitle: true,
    ),
  );
  NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    notificationDetails,
    payload: payloadData,
  );
}

class MyApp extends StatefulWidget {
  final String? initialNewsUrl;
  const MyApp({super.key, this.initialNewsUrl});
  @override
  _MyAppState createState() => _MyAppState();
}

/// This widget sets up Firebase Messaging and subscribes to language-specific topics.
class _MyAppState extends State<MyApp> {
  late FirebaseMessaging messaging;

  @override
  void initState() {
    super.initState();
    initializeFirebaseMessaging();

    // Listen for when the app is opened via a notification tap (background/terminated).
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print("App opened via notification: ${message.messageId}");
      if (message.data.isNotEmpty) {
        String newsUrl = message.data['news_url'] ?? "";
        if (newsUrl.isNotEmpty) {
          final lang = await getPreferredLanguage();
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                selectedNewsUrl: newsUrl,
                language: lang,
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> initializeFirebaseMessaging() async {
    messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Retrieve preferred language from SharedPreferences.
    String lang = await getPreferredLanguage();
    print("Preferred language: $lang");

    // Subscribe to the appropriate topic.
    if (lang == 'hi') {
      await messaging.subscribeToTopic('latestNews_hi');
      await messaging.unsubscribeFromTopic('latestNews_en');
      print("Subscribed to topic: latestNews_hi");
    } else {
      await messaging.subscribeToTopic('latestNews_en');
      await messaging.unsubscribeFromTopic('latestNews_hi');
      print("Subscribed to topic: latestNews_en");
    }

    // Listen for foreground messages.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("Foreground message received: ${message.messageId}");
      if (message.data.isNotEmpty) {
        String title = message.data['title'] ?? 'Latest News';
        String body = message.data['body'] ?? '';
        String newsUrl = message.data['news_url'] ?? '';
        print("FCM Data -> Title: $title, Body: $body, News URL: $newsUrl");
        await showBigTextNotification(title, body, newsUrl);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(
        language: 'hi', // Set preferred language here if needed.
        selectedNewsUrl: widget.initialNewsUrl,
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock device orientation to portrait mode.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Firebase.
  await Firebase.initializeApp();

  // Set up background message handling.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set up local notifications.
  await setupLocalNotifications();

  // Check for an initial message if the app was launched via a notification.
  RemoteMessage? initialMessage =
  await FirebaseMessaging.instance.getInitialMessage();
  String? initialNewsUrl;
  if (initialMessage != null && initialMessage.data.isNotEmpty) {
    initialNewsUrl = initialMessage.data['news_url'];
    print("Initial message news_url: $initialNewsUrl");
  }

  runApp(MyApp(initialNewsUrl: initialNewsUrl));
}
