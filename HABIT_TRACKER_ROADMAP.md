# 🎯 Habit Tracker Implementation Roadmap

> **Project:** AN Life Tracker - Habit Module  
> **Platform:** Flutter  
> **Backend:** Supabase  
> **Estimated Time:** 8-12 hours  
> **Date:** December 29, 2025

---

## 📋 Implementation Plan

### Phase 1: Database Setup (30 minutes)

**Tasks:**
1. ✅ Run `HABIT_TRACKER_SQL.sql` in Supabase SQL Editor
2. ✅ Verify tables created: `habits`, `habit_logs`
3. ✅ Test RLS policies with test user
4. ✅ Confirm indexes created

**Verification:**
```sql
-- Check tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('habits', 'habit_logs');

-- Check RLS enabled
SELECT tablename, rowsecurity FROM pg_tables 
WHERE tablename IN ('habits', 'habit_logs');
```

---

### Phase 2: Models & Data Layer (1 hour)

**File:** `lib/core/models/habit.dart`
```dart
class Habit {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String frequency;
  final int targetCount;
  final String color;
  final String icon;
  final bool isArchived;
  final List<String> activeMonths;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Constructor, fromJson, toJson methods
}
```

**File:** `lib/core/models/habit_log.dart`
```dart
class HabitLog {
  final String id;
  final String userId;
  final String habitId;
  final DateTime date;
  final bool completed;
  final int count;
  final String? notes;
  final DateTime createdAt;

  // Constructor, fromJson, toJson methods
}
```

**File:** `lib/core/models/models.dart` (Add exports)
```dart
export 'habit.dart';
export 'habit_log.dart';
```

---

### Phase 3: Supabase Service Methods (1 hour)

**File:** `lib/core/services/supabase_service.dart` (Add methods)

```dart
// ==================== HABITS ====================

// Get all habits for current user
Future<List<Map<String, dynamic>>> getHabits() async {
  final response = await client
      .from('habits')
      .select()
      .eq('user_id', currentUserId!)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
}

// Get friend's habits (view only)
Future<List<Map<String, dynamic>>> getFriendHabits(String friendId) async {
  final response = await client
      .from('habits')
      .select()
      .eq('user_id', friendId)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
}

// Add new habit
Future<Map<String, dynamic>> addHabit({
  required String name,
  String? description,
  String? color,
  String? icon,
}) async {
  final now = DateTime.now();
  final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  
  final response = await client
      .from('habits')
      .insert({
        'user_id': currentUserId,
        'name': name,
        'description': description,
        'color': color ?? '#ff6b35',
        'icon': icon ?? '✓',
        'active_months': [monthKey],
      })
      .select()
      .single();
  return response;
}

// Update habit
Future<void> updateHabit(String habitId, Map<String, dynamic> updates) async {
  await client
      .from('habits')
      .update(updates)
      .eq('id', habitId);
}

// Delete habit (and all logs)
Future<void> deleteHabit(String habitId) async {
  await client
      .from('habits')
      .delete()
      .eq('id', habitId);
}

// ==================== HABIT LOGS ====================

// Get logs for a date range
Future<List<Map<String, dynamic>>> getHabitLogs({
  required DateTime startDate,
  required DateTime endDate,
  String? habitId,
}) async {
  var query = client
      .from('habit_logs')
      .select()
      .eq('user_id', currentUserId!)
      .gte('date', startDate.toIso8601String().split('T')[0])
      .lte('date', endDate.toIso8601String().split('T')[0]);
  
  if (habitId != null) {
    query = query.eq('habit_id', habitId);
  }
  
  final response = await query.order('date', ascending: true);
  return List<Map<String, dynamic>>.from(response);
}

// Get friend's habit logs
Future<List<Map<String, dynamic>>> getFriendHabitLogs({
  required String friendId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final response = await client
      .from('habit_logs')
      .select()
      .eq('user_id', friendId)
      .gte('date', startDate.toIso8601String().split('T')[0])
      .lte('date', endDate.toIso8601String().split('T')[0])
      .order('date', ascending: true);
  return List<Map<String, dynamic>>.from(response);
}

// Toggle habit log (upsert)
Future<Map<String, dynamic>> toggleHabitLog({
  required String habitId,
  required DateTime date,
}) async {
  final dateStr = date.toIso8601String().split('T')[0];
  
  // Check if log exists
  final existing = await client
      .from('habit_logs')
      .select()
      .eq('habit_id', habitId)
      .eq('date', dateStr)
      .maybeSingle();
  
  if (existing != null) {
    // Toggle existing log
    final response = await client
        .from('habit_logs')
        .update({'completed': !existing['completed']})
        .eq('id', existing['id'])
        .select()
        .single();
    return response;
  } else {
    // Create new log
    final response = await client
        .from('habit_logs')
        .insert({
          'user_id': currentUserId,
          'habit_id': habitId,
          'date': dateStr,
          'completed': true,
        })
        .select()
        .single();
    return response;
  }
}

// Get weekly habit completion rate
Future<Map<String, dynamic>> getWeeklyHabitStats(String userId) async {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  
  final habits = await client
      .from('habits')
      .select()
      .eq('user_id', userId);
  
  final logs = await client
      .from('habit_logs')
      .select()
      .eq('user_id', userId)
      .gte('date', weekStart.toIso8601String().split('T')[0]);
  
  final totalHabits = habits.length;
  final totalPossibleCompletions = totalHabits * 7; // 7 days
  final actualCompletions = (logs as List).where((l) => l['completed'] == true).length;
  
  final completionRate = totalPossibleCompletions > 0 
      ? (actualCompletions / totalPossibleCompletions * 100).round()
      : 0;
  
  return {
    'totalHabits': totalHabits,
    'completedThisWeek': actualCompletions,
    'completionRate': completionRate,
  };
}
```

---

### Phase 4: AppProvider Integration (1 hour)

**File:** `lib/core/providers/app_provider.dart` (Add habit state)

```dart
class AppProvider extends ChangeNotifier {
  // ... existing code ...
  
  // Habit state
  List<Habit> _habits = [];
  Map<String, Map<String, HabitLog>> _habitLogs = {}; // date -> habitId -> log
  DateTime _currentHabitMonth = DateTime.now();
  
  // Getters
  List<Habit> get habits => _habits;
  Map<String, Map<String, HabitLog>> get habitLogs => _habitLogs;
  DateTime get currentHabitMonth => _currentHabitMonth;
  
  List<Habit> get currentMonthHabits {
    final monthKey = '${_currentHabitMonth.year}-${_currentHabitMonth.month.toString().padLeft(2, '0')}';
    return _habits.where((h) => 
      !h.isArchived && (h.activeMonths.isEmpty || h.activeMonths.contains(monthKey))
    ).toList();
  }
  
  // Methods
  Future<void> loadHabits() async {
    try {
      final habitsData = await _supabaseService.getHabits();
      _habits = habitsData.map((data) => Habit.fromJson(data)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading habits: $e');
    }
  }
  
  Future<void> loadHabitLogs(DateTime month) async {
    try {
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);
      
      final logsData = await _supabaseService.getHabitLogs(
        startDate: firstDay,
        endDate: lastDay,
      );
      
      // Transform to map: date -> habitId -> log
      _habitLogs.clear();
      for (final logData in logsData) {
        final log = HabitLog.fromJson(logData);
        final dateKey = log.date.toIso8601String().split('T')[0];
        
        if (!_habitLogs.containsKey(dateKey)) {
          _habitLogs[dateKey] = {};
        }
        _habitLogs[dateKey]![log.habitId] = log;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading habit logs: $e');
    }
  }
  
  Future<void> addHabit(Habit habit) async {
    try {
      final data = await _supabaseService.addHabit(
        name: habit.name,
        description: habit.description,
        color: habit.color,
        icon: habit.icon,
      );
      _habits.add(Habit.fromJson(data));
      notifyListeners();
    } catch (e) {
      print('Error adding habit: $e');
      rethrow;
    }
  }
  
  Future<void> toggleHabitLog(String habitId, DateTime date) async {
    try {
      // Optimistic update
      final dateKey = date.toIso8601String().split('T')[0];
      final existingLog = _habitLogs[dateKey]?[habitId];
      
      if (existingLog != null) {
        // Toggle existing
        _habitLogs[dateKey]![habitId] = HabitLog(
          id: existingLog.id,
          userId: existingLog.userId,
          habitId: existingLog.habitId,
          date: existingLog.date,
          completed: !existingLog.completed,
          count: existingLog.count,
          notes: existingLog.notes,
          createdAt: existingLog.createdAt,
        );
      } else {
        // Create new
        _habitLogs[dateKey] = _habitLogs[dateKey] ?? {};
        _habitLogs[dateKey]![habitId] = HabitLog(
          id: '', // Will be updated after server response
          userId: _supabaseService.currentUserId!,
          habitId: habitId,
          date: date,
          completed: true,
          count: 0,
          createdAt: DateTime.now(),
        );
      }
      
      notifyListeners();
      
      // Server update
      final result = await _supabaseService.toggleHabitLog(
        habitId: habitId,
        date: date,
      );
      
      // Update with server data
      final log = HabitLog.fromJson(result);
      _habitLogs[dateKey]![habitId] = log;
      notifyListeners();
    } catch (e) {
      print('Error toggling habit: $e');
      // Reload to sync with server
      await loadHabitLogs(_currentHabitMonth);
    }
  }
  
  Future<void> deleteHabit(String habitId) async {
    try {
      await _supabaseService.deleteHabit(habitId);
      _habits.removeWhere((h) => h.id == habitId);
      
      // Remove all logs for this habit
      for (final dateKey in _habitLogs.keys) {
        _habitLogs[dateKey]!.remove(habitId);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error deleting habit: $e');
      rethrow;
    }
  }
  
  void setHabitMonth(DateTime month) {
    _currentHabitMonth = month;
    loadHabitLogs(month);
  }
}
```

---

### Phase 5: UI Components (3-4 hours)

#### 5.1 Main Habits Page

**File:** `lib/features/habits/habits_page.dart`

**Key Features:**
- AppBar with month navigation
- Stats cards (total habits, completed today, progress)
- Today's habit checklist
- View full calendar button
- Add habit button
- Responsive design

**Layout:**
```dart
Scaffold(
  appBar: AppBar(...),
  body: SingleChildScrollView(
    child: Column(
      children: [
        MonthNavigationBar(),
        HabitStatsCards(),
        TodayHabitsList(),
        ViewFullCalendarButton(),
        WeeklyProgressChart(),
      ],
    ),
  ),
  floatingActionButton: AddHabitButton(),
)
```

#### 5.2 Habit Stats Cards

**File:** `lib/features/habits/widgets/habit_stats_card.dart`

3 cards showing:
1. Total active habits
2. Completed today (X/Y)
3. Monthly progress with progress bar

#### 5.3 Today's Habits List

**File:** `lib/features/habits/widgets/today_habits_list.dart`

Displays:
- Checkboxes for each habit
- Habit name and icon
- Monthly completion percentage
- Tap to toggle completion

#### 5.4 Full Calendar View (Bottom Sheet)

**File:** `lib/features/habits/widgets/habit_calendar_sheet.dart`

Shows:
- Month calendar grid
- All days of the month
- Habit rows with daily checkboxes
- Progress bars per habit
- Swipe to dismiss

#### 5.5 Add Habit Dialog

**File:** `lib/features/habits/widgets/add_habit_dialog.dart`

Form with:
- Habit name (required)
- Description (optional)
- Icon picker
- Color picker
- Save button

---

### Phase 6: Navigation Integration (30 minutes)

**File:** `lib/features/navigation/main_navigation.dart`

Update:
```dart
final List<Widget> _pages = [
  const HomePage(),
  const FocusPage(),
  const CaloriesPage(),
  const HabitsPage(), // NEW
  const FriendsPage(),
  const LeaderboardPage(),
];

// Update bottom nav items
Row(
  children: [
    _buildNavItem(0, Icons.home_rounded, 'Home'),
    _buildNavItem(1, Icons.psychology_rounded, 'Focus'),
    _buildNavItem(2, Icons.apple_rounded, 'Nutrition'),
    _buildNavItem(3, Icons.check_circle_rounded, 'Habits'), // NEW
    _buildNavItem(4, Icons.people_rounded, 'Friends'),
    _buildNavItem(5, Icons.leaderboard_rounded, 'Board'),
  ],
)
```

---

### Phase 7: Friend Integration (1-2 hours)

#### 7.1 Friend Profile - Add Habits Tab

**File:** `lib/features/friends/friend_profile_page.dart`

Add new tab:
```dart
TabBar(
  tabs: [
    Tab(text: 'Overview'),
    Tab(text: 'Focus'),
    Tab(text: 'Calories'),
    Tab(text: 'Habits'), // NEW
  ],
)
```

**New Widget:** `FriendHabitsTab`
- Shows friend's habits (read-only)
- Displays completion status
- Cannot toggle (view only)

#### 7.2 Leaderboard - Add Habit Metric

**File:** `lib/features/leaderboard/leaderboard_page.dart`

Add 3rd metric option:
```dart
Row(
  children: [
    MetricButton('Focus', _activeMetric == 'focus'),
    MetricButton('Calories', _activeMetric == 'calories'),
    MetricButton('Habits', _activeMetric == 'habits'), // NEW
  ],
)
```

Calculate habit completion rate:
```dart
final habitStats = await supabaseService.getWeeklyHabitStats(friendId);
final completionRate = habitStats['completionRate'];
```

---

### Phase 8: Polish & Testing (1-2 hours)

**Tasks:**
1. Add loading spinners
2. Add error handling with user-friendly messages
3. Add empty states ("No habits yet")
4. Add animations (check mark, progress bars)
5. Test all flows:
   - Create habit
   - Toggle completion
   - Navigate months
   - Delete habit
   - View friend's habits
   - Check leaderboard
6. Performance optimization
7. Responsive design tweaks for 6-inch phones

---

## 🔍 Testing Checklist

### User Flow Tests

- [ ] Create a new habit
- [ ] Toggle habit completion for today
- [ ] Toggle habit completion for past days
- [ ] Navigate to previous/next month
- [ ] View full calendar
- [ ] Delete a habit
- [ ] View stats cards update in real-time
- [ ] View friend's habits
- [ ] Check habit metric in leaderboard
- [ ] Test with 0 habits (empty state)
- [ ] Test with 10+ habits (scrolling)

### Edge Cases

- [ ] Toggle habit on future date (should be disabled)
- [ ] Delete habit with many logs
- [ ] Create habit with very long name
- [ ] Network error handling
- [ ] RLS policy enforcement (can't see stranger's habits)
- [ ] Month with 28/29/30/31 days
- [ ] Year boundary (Dec → Jan)

### Performance

- [ ] Load habits (< 500ms)
- [ ] Toggle habit (< 200ms with optimistic update)
- [ ] Navigate months (< 300ms)
- [ ] Smooth scrolling
- [ ] No UI janks

---

## 🎨 Design Specifications

### Colors

```dart
// Habit completion colors
const habitGreen = Color(0xFF10B981);  // Completed
const habitGray = Color(0xFFE5E7EB);   // Not completed
const habitRed = Color(0xFFEF4444);    // Missed (past)
const habitBlue = Color(0xFF3B82F6);   // Today highlight

// Progress bar colors
const progressGreen = Color(0xFF10B981);  // > 80%
const progressYellow = Color(0xFFF59E0B); // 50-79%
const progressRed = Color(0xFFEF4444);    // < 50%
```

### Spacing

```dart
// Card padding
const cardPadding = 16.0;
const cardSpacing = 12.0;

// List item height
const habitItemHeight = 60.0;

// Icon sizes
const habitIconSize = 24.0;
const checkboxSize = 28.0;
```

### Typography

```dart
// Titles
const titleStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
);

// Habit name
const habitNameStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

// Stats
const statsStyle = TextStyle(
  fontSize: 14,
  color: Colors.grey,
);
```

---

## 📊 Success Metrics

### Phase Completion Criteria

**Phase 1-3 (Database + Models):**
- ✓ Tables created and verified
- ✓ Models compile without errors
- ✓ Service methods return data

**Phase 4-5 (UI):**
- ✓ Habits page renders
- ✓ Can create and view habits
- ✓ Can toggle completion

**Phase 6-7 (Integration):**
- ✓ Navigation works
- ✓ Friends can view habits
- ✓ Leaderboard shows habit metric

**Phase 8 (Polish):**
- ✓ No crashes or errors
- ✓ Smooth animations
- ✓ All tests pass

---

## 🚀 Next Steps

1. **Run SQL**: Execute `HABIT_TRACKER_SQL.sql`
2. **Create Models**: Start with Phase 2
3. **Add Service Methods**: Complete Phase 3
4. **Build Basic UI**: Focus on Phase 5.1-5.3 first
5. **Test Core Flow**: Create → Toggle → View
6. **Add Advanced Features**: Calendar, charts, friend view
7. **Polish**: Animations, error handling, edge cases

---

## 📝 Notes

- Keep UI simple and mobile-friendly
- Use optimistic updates for instant feedback
- Cache habit data to reduce network calls
- Consider offline support in future versions
- Add push notifications for habit reminders (future feature)

---

**Ready to start? Begin with Phase 1! 🎯**
