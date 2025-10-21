import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/notification_service.dart';
import '../../../services/user_settings_service.dart';

class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({super.key});

  @override
  State<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
  bool _mealReminders = false;
  bool _testNotifications = false;
  bool _notificationsEnabled = false;
  bool _isLoading = true;
  String _testStatus = '';
  String _platformInfo = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load notification settings and status with cross-platform support
  Future<void> _loadSettings() async {
    try {
      // Initialize services
      await UserSettingsService.instance.initialize();

      // Check platform and notification status
      if (kIsWeb) {
        _notificationsEnabled = true; // Web has basic support
        _platformInfo = 'Web (Limited functionality)';
      } else {
        _notificationsEnabled =
            await NotificationService.instance.areNotificationsEnabled();
        _platformInfo = 'Mobile (Full functionality)';
      }

      // Load user preferences
      final prefs =
          await UserSettingsService.instance.getNotificationPreferences();

      // Get test notification status
      final testStatus =
          await NotificationService.instance.getTestNotificationStatus();

      if (mounted) {
        setState(() {
          _mealReminders = prefs?['meal_reminders'] ?? false;
          _testNotifications = testStatus['isRunning'] ?? false;
          _testStatus = testStatus['isRunning']
              ? 'Running (${testStatus['pendingCount']} pending)'
              : 'Stopped';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _platformInfo = 'Error loading';
        });
      }
    }
  }

  /// Update meal reminder settings
  Future<void> _updateMealReminder(bool value) async {
    try {
      setState(() {
        _mealReminders = value;
      });

      // Update preferences
      await UserSettingsService.instance.updateNotificationPreferences({
        'meal_reminders': value,
      });

      // Schedule or cancel meal reminder
      await NotificationService.instance.updateMealReminderPreference(value);

      if (mounted) {
        final message = value
            ? (kIsWeb
                ? 'Promemoria pasti attivati (limitato su web)'
                : 'Promemoria pasti attivati alle 15:00')
            : 'Promemoria pasti disattivati';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      print('Error updating meal reminder: $e');
      // Revert state on error
      setState(() {
        _mealReminders = !value;
      });
    }
  }

  /// Toggle test notifications
  Future<void> _toggleTestNotifications(bool value) async {
    try {
      setState(() {
        _testNotifications = value;
        _testStatus = value ? 'Starting...' : 'Stopping...';
      });

      if (value) {
        await NotificationService.instance.startTestNotifications();
        if (mounted) {
          final message = kIsWeb
              ? '🧪 Test notifications started! You should see browser notifications every 5 minutes for the next 2 hours.'
              : '🧪 Test notifications started! You\'ll receive notifications every 5 minutes for the next 2 hours.';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), duration: Duration(seconds: 5)),
          );
        }
      } else {
        await NotificationService.instance.stopTestNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🔕 Test notifications stopped')),
          );
        }
      }

      // Refresh status to get current state
      await _loadSettings();
    } catch (e) {
      print('Error toggling test notifications: $e');

      // Show user-friendly error message
      if (mounted) {
        final errorMessage = kIsWeb
            ? '❌ Error: Please allow notifications in your browser settings first'
            : '❌ Error: Please check notification permissions in device settings';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 4),
          ),
        );
      }

      // Revert state on error and refresh
      setState(() {
        _testNotifications = !value;
        _testStatus = 'Error';
      });

      // Reload to get actual state
      await _loadSettings();
    }
  }

  /// Send immediate test notification
  Future<void> _sendTestNotification() async {
    try {
      await NotificationService.instance.showTestNotification();
      if (mounted) {
        final message = kIsWeb
            ? '📱 Test notification sent! Check your browser notifications.'
            : '📱 Test notification sent! Check your notification panel.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green[600],
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error sending test notification: $e');
      if (mounted) {
        final errorMessage = kIsWeb
            ? '❌ Error: Please allow notifications in your browser settings'
            : '❌ Error: Check notification permissions in device settings';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // System notification status with platform info
        Card(
          margin: EdgeInsets.symmetric(vertical: 1.h),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _notificationsEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: _notificationsEnabled ? Colors.green : Colors.red,
                      size: 6.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stato Notifiche Sistema',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                          Text(
                            _notificationsEnabled ? 'Attivate' : 'Disattivate',
                            style: TextStyle(
                              color: _notificationsEnabled
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Platform: $_platformInfo',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Meal reminders setting
        Card(
          margin: EdgeInsets.symmetric(vertical: 1.h),
          child: ListTile(
            leading: Icon(
              Icons.restaurant,
              size: 6.w,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              'Promemoria Pasti (15:00)',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp),
            ),
            subtitle: Text(
              kIsWeb
                  ? 'Preferenza promemoria pasti (funzionalità limitata su web)'
                  : 'Ricevi un promemoria giornaliero alle 15:00 per registrare i tuoi pasti',
              style: TextStyle(fontSize: 10.sp),
            ),
            trailing: Switch(
              value: _mealReminders,
              onChanged: _updateMealReminder,
              activeColor: Theme.of(context).primaryColor,
            ),
          ),
        ),

        // Test notifications setting
        Card(
          margin: EdgeInsets.symmetric(vertical: 1.h),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.science, size: 6.w, color: Colors.orange),
                title: Text(
                  'Test Notifications (Every 5min)',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kIsWeb
                          ? 'Test notification simulation for web platform'
                          : 'Ricevi una notifica ogni 5 minuti per testare il funzionamento',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Status: $_testStatus',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w500,
                        color: _testNotifications
                            ? Colors.green
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: Switch(
                  value: _testNotifications,
                  onChanged: _toggleTestNotifications,
                  activeColor: Colors.orange,
                ),
              ),

              // Test notification button
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 3.w),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendTestNotification,
                    icon: const Icon(Icons.send, size: 16),
                    label: Text(
                      kIsWeb
                          ? 'Send Test Notification (Simulated)'
                          : 'Send Test Notification Now',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Platform-specific help text
        if (kIsWeb)
          Container(
            margin: EdgeInsets.symmetric(vertical: 2.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 5.w),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'Web Notifications Setup:',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  '1. Click "Allow" when browser asks for notification permission\n'
                  '2. Test notifications will appear as browser notifications\n'
                  '3. Make sure your browser notifications are not blocked',
                  style: TextStyle(fontSize: 10.sp, color: Colors.blue[800]),
                ),
              ],
            ),
          ),

        if (!kIsWeb && !_notificationsEnabled)
          Container(
            margin: EdgeInsets.symmetric(vertical: 2.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 5.w),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'Enable Notifications:',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  '1. Go to device Settings > Apps > NutriVita\n'
                  '2. Enable "Notifications" permission\n'
                  '3. Allow "Exact alarm" permission for Android 12+',
                  style: TextStyle(fontSize: 10.sp, color: Colors.orange[800]),
                ),
              ],
            ),
          ),

        // Debug info (only in debug mode)
        if (kDebugMode)
          Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(26),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debug Info:',
                  style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Platform: ${kIsWeb ? 'Web' : 'Mobile'}',
                  style: TextStyle(fontSize: 8.sp),
                ),
                Text(
                  'Notifications Enabled: $_notificationsEnabled',
                  style: TextStyle(fontSize: 8.sp),
                ),
                Text(
                  'Service Initialized: ${NotificationService.instance.isInitialized}',
                  style: TextStyle(fontSize: 8.sp),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
