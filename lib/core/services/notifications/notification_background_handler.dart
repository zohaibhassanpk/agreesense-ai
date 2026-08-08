import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../firebase_options.dart';

/// Background message handler. Sensor alerts contain an FCM notification
/// payload, so Android/iOS display the system popup themselves while the app
/// is backgrounded or terminated.
///
/// This handler intentionally does not call the local-notifications plugin:
/// doing so would display a duplicate notification on platforms where FCM has
/// already placed the notification payload in the system tray.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
