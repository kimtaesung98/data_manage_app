class AppConstants {
  // Supply at build time: flutter run --dart-define=ADMIN_PASSWORD=yourpassword
  // If omitted, admin access is disabled (empty string never matches).
  static const String adminPassword =
      String.fromEnvironment('ADMIN_PASSWORD');
  static const String firestoreCollection = 'packets';
  static const int maxLogItems = 100;
  static const String bgChannelId = 'data_bridge_channel';
  static const int bgNotificationId = 888;
}
