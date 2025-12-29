# 🔔 Smart Notification System Documentation

## Overview
The app now includes a comprehensive smart notification system that helps users stay consistent and motivated based on their usage patterns.

---

## 📱 Notification Types

### 1. **Morning Motivation** (8:00 AM)
**Purpose**: Start the day with inspiration

**Messages** (rotates daily):
- "Good morning! ☀️ Ready to make today count?"
- "Rise and shine! ✨ Your goals are waiting!"
- "New day, new opportunities! 🌅 Let's focus!"
- "Good morning, champion! 💪 Time to level up!"
- "Morning! 🌞 Your future self will thank you!"

**Frequency**: Daily at 8:00 AM
**Can be disabled**: Yes

---

### 2. **Daily Goal Reminder** (12:00 PM)
**Purpose**: Check progress midday

**Message**: "Daily Goal Check! 🎯 How's your progress today? Time for a focus session!"

**Frequency**: Daily at 12:00 PM
**Can be disabled**: Yes

---

### 3. **Inactivity Reminders** (Smart Timing)
**Purpose**: Nudge users who haven't opened the app

**How it works**:
1. If app not opened by 12:00 PM → First reminder
2. If still not opened after 1 hour → Follow-up reminder
3. Continues every hour until app is opened

**Messages**:
- "Time to focus! 🎯 You haven't checked in today. Start a focus session now!"
- "We miss you! 👋 It's been {X}h since your last session. Come back and crush your goals!"

**Frequency**: Smart - only when needed
**Can be disabled**: Yes

---

### 4. **Evening Review** (8:00 PM)
**Purpose**: Reflect on daily progress

**Message**: "Evening Review 📊 How did today go? Review your progress and plan tomorrow!"

**Frequency**: Daily at 8:00 PM
**Can be disabled**: Yes

---

### 5. **Streak Protection** (10:00 PM)
**Purpose**: Prevent streak from breaking

**Message**: "Streak Alert! 🔥 Don't break your streak! Log some activity before midnight!"

**Frequency**: Daily at 10:00 PM
**Can be disabled**: Yes

---

### 6. **Goal Completion** (Instant)
**Purpose**: Celebrate achievements

**Message**: "🎉 Goal Completed! Congrats! You completed: {goal_name}"

**Trigger**: When user completes a goal
**Can be disabled**: No (achievement notifications)

---

### 7. **Milestone Reached** (Instant)
**Purpose**: Celebrate milestones

**Examples**:
- "🏆 Milestone Reached! You've completed 100 focus sessions!"
- "🏆 Milestone Reached! 1000 minutes of focused work!"

**Trigger**: When user reaches milestones
**Can be disabled**: No (achievement notifications)

---

### 8. **Friend Reminders** (Instant)
**Purpose**: Friends can send motivational messages

**Messages** (7 pre-written):
1. 🎯 "Hey! Start focusing!"
2. 📚 "Let's study together!"
3. 📱 "Open the app!"
4. 💪 "Time to be productive!"
5. ⏰ "Don't forget your focus session!"
6. 🔥 "Let's keep the streak going!"
7. 🏆 "Challenge accepted? Let's compete!"

**Trigger**: When a friend sends a reminder
**Can be disabled**: No (friend interactions)

---

## ⚙️ Notification Settings

### How to Access
1. Open **Profile** page
2. Go to **Notifications** section
3. Click **"Customize"** button
4. Toggle notifications on/off

### Available Settings
- ✅ Morning Motivation
- ✅ Daily Goal Reminders
- ✅ Inactivity Reminders
- ✅ Evening Review
- ✅ Streak Protection

**Note**: Achievement and friend notifications cannot be disabled.

---

## 🔧 Technical Implementation

### Architecture

```
NotificationService (Singleton)
├── Smart Notifications
│   ├── Scheduled (Daily)
│   │   ├── Morning (8 AM)
│   │   ├── Noon (12 PM)
│   │   ├── Evening (8 PM)
│   │   └── Night (10 PM)
│   └── Smart (Behavior-based)
│       └── Inactivity (Hourly check)
├── Achievement Notifications
│   ├── Goal Completion
│   └── Milestones
└── Friend Notifications
    ├── Reminders
    └── Status Updates
```

### Key Features

**1. Usage Tracking**
- Tracks every app open with timestamp
- Stores in SharedPreferences
- Used for inactivity detection

**2. Smart Scheduling**
- Uses timezone-aware scheduling
- Repeats daily for recurring notifications
- Automatically reschedules after device reboot

**3. Notification Channels**
Android notification channels:
- `morning_motivation` - Morning messages
- `daily_goal_reminders` - Goal reminders
- `inactivity_reminders` - Inactivity nudges
- `evening_review` - Evening reflections
- `streak_protection` - Streak alerts
- `achievements` - Goal/milestone celebrations
- `goal_completion` - Goal completions
- `milestones` - Milestone achievements
- `friend_reminders` - Friend messages

**4. Persistence**
- Settings stored in SharedPreferences
- Survives app restarts
- User preferences respected

---

## 📊 Usage Monitoring System

### What's Tracked
1. **Last App Open Time**
   - Stored: Every time app opens
   - Used for: Inactivity detection

2. **Notification Preferences**
   - Stored: When user changes settings
   - Used for: Determining which notifications to send

### How It Works

```
User Opens App
    ↓
Track app open time
    ↓
Cancel pending inactivity notifications
    ↓
Start hourly monitoring
    ↓
Check if inactivity notifications needed
    ↓
Send if conditions met
```

---

## 🎯 Notification Logic

### Inactivity Detection

```dart
if (current_time >= 12:00 PM && last_open != today) {
  → Send "Time to focus!" notification
}

if (hours_since_last_open >= 1) {
  → Send "We miss you!" notification
  → Repeat every hour until app opened
}
```

### Daily Scheduling

```dart
Morning: Schedule for 8:00 AM daily
Noon: Schedule for 12:00 PM daily
Evening: Schedule for 8:00 PM daily
Night: Schedule for 10:00 PM daily
```

### Friend Notifications

```dart
When friend sends reminder:
  1. Save to Supabase database
  2. Poll every 10 seconds for new notifications
  3. Show local notification when detected
  4. Works for both online and offline recipients
```

---

## 💡 Best Practices

### For Users
1. **Enable permissions**: Allow notifications in device settings
2. **Customize settings**: Turn off notifications you don't want
3. **Check timing**: Notifications scheduled at fixed times
4. **Battery**: Smart notifications use minimal battery

### For Developers
1. **Test timezone handling**: Works across different timezones
2. **Handle permissions**: Request notification permissions properly
3. **Respect settings**: Always check if notification type is enabled
4. **Track opens**: Call `_trackAppOpen()` on app launch

---

## 🐛 Troubleshooting

### Notifications Not Appearing

**Check 1: Device Permissions**
- Go to device Settings → Apps → AN Life Tracker → Notifications
- Ensure notifications are enabled

**Check 2: App Settings**
- Open Profile → Notifications → Customize
- Check if notification type is enabled

**Check 3: Time Settings**
- Ensure device time is correct
- Notifications use device timezone

**Check 4: Battery Optimization**
- Some Android devices kill background processes
- Disable battery optimization for the app

### Notifications Appearing Too Often

**Solution**: 
- Open Profile → Notifications → Customize
- Disable "Inactivity Reminders"

### Not Receiving Friend Notifications

**Check**:
1. Both users are friends
2. Sender actually sent the notification
3. Wait 10 seconds (polling interval)
4. Check notification permissions

---

## 📈 Notification Analytics (Future)

### Metrics to Track
- Notification delivery rate
- User engagement after notifications
- Most effective notification times
- Most used friend reminder messages
- Settings preferences by user segment

---

## 🔮 Future Enhancements

### Planned Features
1. **Smart Timing**
   - Learn user's active hours
   - Send notifications at optimal times

2. **Contextual Messages**
   - Based on user's goal progress
   - Based on friend activity
   - Based on streak length

3. **Rich Notifications**
   - Quick actions (Start focus session)
   - Progress bars
   - Images/animations

4. **Custom Messages**
   - Let users write their own reminders
   - Schedule custom notifications

5. **Notification History**
   - View all past notifications
   - Re-trigger missed ones

---

## 📝 Code Examples

### Trigger Achievement Notification

```dart
// When user completes a goal
await NotificationService().showGoalCompletedNotification('Complete 5 focus sessions');

// When user reaches a milestone
await NotificationService().showMilestoneNotification('You\'ve completed 100 focus sessions!');
```

### Change Notification Settings

```dart
// Enable/disable a notification type
await NotificationService().setNotificationSetting('morning_motivation', false);
```

### Track App Usage

```dart
// Called automatically when app opens
// But can be called manually if needed
await NotificationService()._trackAppOpen();
```

---

## 🔐 Privacy & Permissions

### Required Permissions
- **Android**: POST_NOTIFICATIONS (Android 13+)
- **iOS**: Local notifications permission

### Data Storage
- Settings: Local (SharedPreferences)
- Friend notifications: Supabase database
- Usage tracking: Local (SharedPreferences)

### Privacy
- No notification content sent to servers
- Friend messages stored securely in database
- Usage data stays on device

---

## 📱 Platform-Specific Notes

### Android
- Uses notification channels for categorization
- Respects "Do Not Disturb" mode
- Shows in notification shade
- Can be swiped away

### iOS
- Uses UserNotifications framework
- Respects Focus modes
- Shows in Notification Center
- Can customize notification appearance

---

## ✅ Testing Checklist

- [ ] Morning notification appears at 8 AM
- [ ] Daily goal reminder appears at 12 PM
- [ ] Evening review appears at 8 PM
- [ ] Streak protection appears at 10 PM
- [ ] Inactivity reminder appears after 12 PM if app not opened
- [ ] Hourly reminders stop when app is opened
- [ ] Settings page works correctly
- [ ] Toggling settings enables/disables notifications
- [ ] Friend reminders appear within 10 seconds
- [ ] Achievement notifications appear instantly
- [ ] Notifications survive app restart
- [ ] Notifications respect device timezone

---

## 📞 Support

If users experience issues with notifications:
1. Check device notification permissions
2. Verify app notification settings
3. Ensure device time/timezone is correct
4. Try reinstalling the app
5. Report bug with device model and OS version

---

**Last Updated**: December 29, 2025
**Version**: 1.0.0
