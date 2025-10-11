import 'package:firebase_messaging/firebase_messaging.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _firestoreService;

  NotificationService(this._firestoreService);

  Future<void> initNotifications(String userId) async {
    // Request permission from the user
    await _fcm.requestPermission();

    // Get the FCM token for this device
    final String? token = await _fcm.getToken();
    print("FCM Token: $token");

    // Save the token to Firestore
    if (userId.isNotEmpty && token != null) {
      await _firestoreService.saveUserFcmToken(userId, token);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      if(userId.isNotEmpty) {
        _firestoreService.saveUserFcmToken(userId, newToken);
      }
    });
  }
}