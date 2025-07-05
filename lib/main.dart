import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'welcome_screen.dart';
import 'package:provider/provider.dart';
import 'providers/step_goal_provider.dart';
import 'providers/streak_provider.dart';
import 'health_dashboard.dart';
import 'streaks_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/duo_challenge_invite_dialog.dart';
import 'services/character_animation_service.dart';
import 'services/duo_challenge_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message (can be expanded later)
  print('Handling a background message: ${message.messageId}');
}

// Global navigator key to show dialogs from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Function to save FCM token to Firestore
Future<void> _saveFcmTokenToFirestore(String token) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token.isNotEmpty) {
      print('Saving FCM token for user: ${user.uid}');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
      print(
          'FCM token saved to Firestore successfully: ${token.substring(0, 20)}...');
    } else {
      print(
          'Cannot save FCM token: user=${user?.uid}, token=${token.isNotEmpty}');
    }
  } catch (e) {
    print('Error saving FCM token to Firestore: $e');
  }
}

// Function to check for pending duo challenge invites and show popup
Future<void> checkAndShowPendingInvites() async {
  try {
    final duoChallengeService = DuoChallengeService();
    final pendingInvites = await duoChallengeService.checkPendingInvites();

    if (pendingInvites.isNotEmpty) {
      // Show the most recent invite
      final latestInvite = pendingInvites.first;
      final inviterUsername = latestInvite['inviterUsername'] as String;
      final inviteId = latestInvite['inviteId'] as String;

      print('Found pending duo challenge invite from $inviterUsername');

      // Add a small delay to ensure the app is fully loaded
      await Future.delayed(const Duration(milliseconds: 500));

      _showDuoChallengeInviteDialog(inviterUsername, inviteId);
    }
  } catch (e) {
    print('Error checking pending invites: $e');
  }
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('Flutter binding initialized');

    // Set preferred orientations to portrait only
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    print('Screen orientation set');

    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      // Continue without Firebase for now
    }

    // FCM setup
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final fcm = FirebaseMessaging.instance;

    // Request permission
    NotificationSettings settings = await fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    await fcm.setAutoInitEnabled(true);

    // Get the token
    final token = await fcm.getToken();
    print('FCM Token received: ${token?.substring(0, 20) ?? 'null'}...');

    // Save token to Firestore if user is logged in
    if (token != null) {
      await _saveFcmTokenToFirestore(token);
    } else {
      print('Warning: FCM token is null');
    }

    // Listen for token refresh
    fcm.onTokenRefresh.listen((newToken) {
      print('FCM token refreshed: ${newToken.substring(0, 20)}...');
      _saveFcmTokenToFirestore(newToken);
    });

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      print('Message notification: ${message.notification?.title}');
      print('Message notification body: ${message.notification?.body}');

      if (message.data['type'] == 'duo_challenge_invite') {
        print('Processing duo challenge invite notification');
        // Show popup for duo challenge invite
        _showDuoChallengeInviteDialog(
          message.data['inviterUsername'] ?? 'Someone',
          message.data['inviteId'] ?? '',
        );
      }
    });

    // Listen for when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from notification: ${message.data}');
      if (message.data['type'] == 'duo_challenge_invite') {
        print('Processing duo challenge invite from notification tap');
        _showDuoChallengeInviteDialog(
          message.data['inviterUsername'] ?? 'Someone',
          message.data['inviteId'] ?? '',
        );
      }
    });

    // Start preloading character animations at app startup
    print('Main: Starting character animation preloading at app startup...');
    CharacterAnimationService().preloadAnimations().then((_) {
      print('Main: Character animation preloading completed at app startup');
    }).catchError((error) {
      print(
          'Main: Failed to preload character animations at app startup: $error');
    });

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => StepGoalProvider()),
          ChangeNotifierProvider(create: (_) => StreakSettingsProvider()),
          ChangeNotifierProvider(create: (_) => StreakProvider()),
        ],
        child: const MyApp(),
      ),
    );
    print('App started successfully');
  } catch (e) {
    print('Error in main: $e');
    // Show some UI even if there's an error
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing app: $e'),
        ),
      ),
    ));
  }
}

void _showDuoChallengeInviteDialog(String inviterUsername, String inviteId) {
  // Show the dialog using the global navigator key
  if (navigatorKey.currentContext != null) {
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) => DuoChallengeInviteDialog(
        inviterUsername: inviterUsername,
        inviteId: inviteId,
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Check for pending invites when app starts if user is already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        checkAndShowPendingInvites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Add the global navigator key
      debugShowCheckedModeBanner: false,
      title: 'Walkzilla',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: kDebugMode ? const WelcomeScreen() : const HealthDashboard(),
    );
  }
}
