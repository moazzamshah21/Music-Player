import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:umarplayer/models/media_item.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('NotificationService already initialized');
      return;
    }

    print('Initializing NotificationService...');

    // Request notification permission
    await requestPermission();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    print('Notification plugin initialized: $initialized');

    // Create notification channel for Android
    await _createNotificationChannel();

    _isInitialized = true;
    print('NotificationService initialization complete');
  }

  Future<void> requestPermission() async {
    // Check current status
    final currentStatus = await Permission.notification.status;
    print('Current notification permission status: $currentStatus');
    
    if (currentStatus.isGranted) {
      print('Notification permission already granted');
      return;
    }

    // Request notification permission
    print('Requesting notification permission...');
    final status = await Permission.notification.request();
    print('Notification permission request result: $status');
    
    if (status.isDenied) {
      print('⚠️ Notification permission denied - notifications will not work');
    } else if (status.isGranted) {
      print('✅ Notification permission granted');
    } else if (status.isPermanentlyDenied) {
      print('⚠️ Notification permission permanently denied - user must enable in settings');
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'com.umarplayer.channel.audio',
      'Umar Player',
      description: 'Audio playback notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: false,
      showBadge: true,
    );

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
      print('✅ Android notification channel created: ${channel.id}');
    } else {
      print('⚠️ Android notification implementation not available');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  Future<void> showNowPlayingNotification(MediaItem item, {bool isPlaying = false}) async {
    try {
      print('📱 Attempting to show notification for: ${item.title}');
      
      if (!_isInitialized) {
        print('NotificationService not initialized, initializing now...');
        await initialize();
      }

      // Check permission again before showing
      final permissionStatus = await Permission.notification.status;
      print('Permission status before showing: $permissionStatus');
      
      if (!permissionStatus.isGranted) {
        print('⚠️ Notification permission not granted, requesting...');
        final requested = await Permission.notification.request();
        print('Permission request result: $requested');
        
        if (!requested.isGranted) {
          print('❌ Notification permission denied, cannot show notification');
          print('Please enable notifications in app settings');
          return;
        }
      }

      // For large icon, we'll use a drawable resource or download the image
      // For now, we'll skip the large icon to avoid complexity
      final androidDetails = AndroidNotificationDetails(
        'com.umarplayer.channel.audio',
        'Umar Player',
        channelDescription: 'Audio playback notifications',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        styleInformation: BigTextStyleInformation(
          item.artist ?? 'Unknown Artist',
          contentTitle: item.title,
        ),
        enableLights: true,
        playSound: false, // Don't play sound for media notifications
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false, // Don't play sound for media notifications
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      print('Calling _notifications.show()...');
      await _notifications.show(
        1,
        item.title,
        item.artist ?? item.subtitle ?? 'Unknown Artist',
        details,
        payload: item.id,
      );
      
      print('✅ Notification show() called successfully');
      print('Notification should now be visible: ${item.title} by ${item.artist ?? "Unknown"}');
    } catch (e, stackTrace) {
      print('❌ Error showing notification: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Test notification to verify setup
  Future<void> showTestNotification() async {
    try {
      print('🧪 Showing test notification...');
      if (!_isInitialized) {
        await initialize();
      }

      final permissionStatus = await Permission.notification.status;
      if (!permissionStatus.isGranted) {
        print('⚠️ Permission not granted for test notification');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'com.umarplayer.channel.audio',
        'Umar Player',
        channelDescription: 'Audio playback notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      await _notifications.show(
        999,
        'Test Notification',
        'If you see this, notifications are working!',
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
      
      print('✅ Test notification shown');
    } catch (e) {
      print('❌ Error showing test notification: $e');
    }
  }

  Future<void> updateNowPlayingNotification(MediaItem item, {bool isPlaying = false}) async {
    await showNowPlayingNotification(item, isPlaying: isPlaying);
  }

  Future<void> cancelNotification() async {
    await _notifications.cancel(1);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
