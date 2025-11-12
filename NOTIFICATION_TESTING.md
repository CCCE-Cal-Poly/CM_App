# Notification Testing Guide

## Implementation Complete

All 6 notification implementation steps have been completed:

1. **Firestore Rules** - Added fcmTokens subcollection rules 
2. **Dependencies** - flutter_local_notifications v19.5.0 confirmed 
3. **Background Handler** - Enhanced with BigTextStyleInformation and logging 
4. **Cloud Functions** - Improved with duplicate prevention, validation, and cleanup 
5. **Android Manifest** - Added permissions and notification channels 
6. **Deployment** - Cloud Functions deployed successfully 

## 🧪 Testing Instructions

### Step 1: Get Your FCM Token

1. **Run the app** on your Android device or emulator
2. **Check the console/logs** for a message with the 🔑 emoji:
   ```
   🔑 FCM Token: dX...
   ```
3. **Copy the entire token** (it will be a long string like `dX1234567890abcdef...`)

### Step 2: Test from Firebase Console

1. **Open Firebase Console**: https://console.firebase.google.com/project/cm-app-90d65/overview
2. Navigate to **Cloud Messaging** (in the Engage section)
3. Click **"Send your first message"** or **"New notification"**
4. Fill in:
   - **Notification title**: "Test Notification"
   - **Notification text**: "This is a test from Firebase Console"
5. Click **"Send test message"**
6. **Paste your FCM token** from Step 1
7. Click **"Test"**

### Step 3: Verify Notification Received

**When App is in Foreground:**
- You should see the notification displayed by flutter_local_notifications
- Rich notification with BigTextStyleInformation (expandable)
- Console should log: "📬 Received foreground notification: ..."

**When App is in Background:**
- Notification appears in system tray
- Has high importance (shows as heads-up notification)
- Clicking opens the app

**When App is Terminated:**
- Notification still appears
- Background handler processes it
- Check device logs for: " Background notification: ..."

## 📊 What Was Implemented

### Cloud Functions

#### scheduleEventReminder
- **Trigger**: When new event is created
- **What it does**: Creates notification to send 1 hour before event
- **Improvements**:
  - ✅ Validates startTime exists and is future date
  - ✅ Checks for existing reminders (prevents duplicates)
  - ✅ Comprehensive error handling
  - ✅ Rich event data in notification

#### cleanupOldNotifications
- **Schedule**: Runs every 24 hours
- **What it does**: Deletes notifications older than 3 days
- **Purpose**: Prevents database bloat

#### processPendingNotifications
- **Schedule**: Runs every 1 minute
- **What it does**: Sends pending notifications when sendAt time is reached
- **Features**: Batch sending, token cleanup, error handling

### Android Manifest Permissions

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### FCM Default Channel

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />
```

## 🐛 Troubleshooting

### No Token in Logs
- Check Firebase initialization in `main.dart`
- Verify `notification_service.dart` is being called
- Ensure device has Google Play Services (for FCM)

### Notification Not Received
- Verify token is correct and not expired
- Check Firestore rules allow token writes: `firebase deploy --only firestore:rules`
- Check Cloud Functions logs in Firebase Console
- Ensure app has notification permissions granted

### Background Handler Not Working
- Check Android Manifest has required permissions
- Verify `firebaseMessagingBackgroundHandler` is defined in `main.dart`
- Look for errors in device logs

## 📝 Next Steps

1. **Test event reminders**: Create an event that starts in 1-2 hours
2. **Monitor Cloud Functions**: Check logs in Firebase Console
3. **Test notification targeting**: Send to specific user groups
4. **Implement in-app notification list**: Show notification history to users

## 🔗 Resources

- [FCM Flutter Setup](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
