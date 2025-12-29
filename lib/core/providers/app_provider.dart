import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';
import '../services/supabase_service.dart';
import '../services/presence_service.dart';

class AppProvider extends ChangeNotifier {
  User? _user;
  List<FocusSession> _focusSessions = [];
  List<CalorieEntry> _calorieEntries = [];
  final List<Friend> _friends = [];
  bool _isOnline = true;

  // Habit Tracker State
  List<Habit> _habits = [];
  Map<String, List<HabitLog>> _habitLogs = {}; // key: habit_id
  DateTime _selectedMonth = DateTime.now();
  bool _isLoadingHabits = false;

  final _syncService = SyncService();
  final _connectivityService = ConnectivityService();
  final _supabaseService = SupabaseService();
  final _presenceService = PresenceService();

  User? get user => _user;
  List<FocusSession> get focusSessions => _focusSessions;
  List<CalorieEntry> get calorieEntries => _calorieEntries;
  List<Friend> get friends => _friends;
  bool get isOnline => _isOnline;
  PresenceService get presenceService => _presenceService;

  // Habit Tracker Getters
  List<Habit> get habits => _habits.where((h) => h.isActiveInMonth(_selectedMonth)).toList();
  List<Habit> get allHabits => _habits;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoadingHabits => _isLoadingHabits;

  // Get logs for a specific habit
  List<HabitLog> getHabitLogs(String habitId) {
    return _habitLogs[habitId] ?? [];
  }

  // Get log for a specific habit on a specific date
  HabitLog? getHabitLogForDate(String habitId, DateTime date) {
    final logs = _habitLogs[habitId] ?? [];
    final dateStr = date.toIso8601String().split('T')[0];
    try {
      return logs.firstWhere((log) => log.dateKey == dateStr);
    } catch (e) {
      return null;
    }
  }

  AppProvider() {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _syncService.initialize(); // Initialize sync service
    await _loadUserFromSupabase();
    await _loadLocalData();
    _listenToConnectivity();
    
    // Initialize presence service for real-time online status
    await _presenceService.initialize();
    
    // Listen to presence changes to update friend statuses
    _presenceService.addListener(_onPresenceChanged);
  }

  void _onPresenceChanged() {
    // Update friend statuses based on real-time presence
    _updateFriendStatuses();
    notifyListeners();
  }

  void _updateFriendStatuses() {
    for (int i = 0; i < _friends.length; i++) {
      final friend = _friends[i];
      final presence = _presenceService.getUserPresence(friend.id);
      
      if (presence != null) {
        // Update friend with real-time status
        _friends[i] = Friend(
          id: friend.id,
          name: friend.name,
          avatarUrl: friend.avatarUrl,
          status: presence.status,
          currentActivity: presence.activity,
          focusMinutes: presence.focusMinutes,
          weeklyFocusHours: friend.weeklyFocusHours,
          weeklyCaloriesBurned: friend.weeklyCaloriesBurned,
        );
      }
    }
  }

  Future<void> _loadUserFromSupabase() async {
    if (_supabaseService.isAuthenticated) {
      await refreshUserData();
    } else {
      // Load mock data only if not authenticated
      _user = User(
        id: '1',
        fullName: 'Guest',
        email: 'guest@example.com',
        dailyFocusGoal: 180,
        dailyCalorieGoal: 2000,
      );
    }
    notifyListeners();
  }

  void _loadMockData() {
    // This method is no longer used - kept for compatibility
  }

  Future<void> _loadLocalData() async {
    // Load focus sessions from local DB
    final sessions = await _syncService.getFocusSessions();
    _focusSessions = sessions.map((s) => FocusSession(
      id: s['id'] as String,
      durationMinutes: s['duration_minutes'] as int,
      subjectTags: List<String>.from(s['subject_tags']),
      sessionDate: DateTime.parse(s['session_date'] as String),
      completed: s['completed'] as bool,
      focusMode: s['focus_mode'] as String? ?? 'normal',
      breakCount: s['break_count'] as int? ?? 0,
    )).toList();

    // Load calorie entries from local DB
    final entries = await _syncService.getCalorieEntries();
    _calorieEntries = entries.map((e) => CalorieEntry(
      id: e['id'] as String,
      type: e['type'] as String,
      description: e['description'] as String,
      amount: e['amount'] as int,
      entryDate: DateTime.parse(e['entry_date'] as String),
    )).toList();

    notifyListeners();
  }

  void _listenToConnectivity() {
    _connectivityService.connectionStatusStream.listen((isConnected) {
      _isOnline = isConnected;
      notifyListeners();
      
      // Trigger sync when connection is restored
      if (isConnected) {
        _syncService.syncAllData();
      }
    });
  }

  Future<void> addFocusSession(FocusSession session) async {
    print('📝 Adding focus session: ${session.durationMinutes} minutes');
    print('📝 Subject: ${session.subjectTags}');
    print('📝 Mode: ${session.focusMode}');
    
    // Add to local list FIRST and notify immediately
    _focusSessions.insert(0, session); // Insert at beginning for latest first
    notifyListeners();
    print('✅ Session added to list. Total: ${_focusSessions.length}');

    // Save to local DB in background
    try {
      await _syncService.addFocusSession({
        'id': session.id,
        'user_id': _user?.id ?? _supabaseService.currentUserId ?? '1',
        'duration_minutes': session.durationMinutes,
        'subject_tags': session.subjectTags,
        'session_date': session.sessionDate.toIso8601String(),
        'completed': session.completed,
        'focus_mode': session.focusMode,
        'break_count': session.breakCount,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('💾 Focus session saved to local DB');
      
      // Trigger sync to cloud if online
      if (_isOnline && _supabaseService.isAuthenticated) {
        _syncService.syncAllData(); // Don't await - let it run in background
      }
    } catch (e) {
      print('❌ Error saving focus session: $e');
    }
  }

  Future<void> addCalorieEntry(CalorieEntry entry) async {
    // Add to local list
    _calorieEntries.add(entry);
    notifyListeners();

    // Save to local DB and sync
    await _syncService.addCalorieEntry({
      'id': entry.id,
      'user_id': _user?.id ?? '1',
      'type': entry.type,
      'description': entry.description,
      'amount': entry.amount,
      'entry_date': entry.entryDate.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Reload from database to ensure persistence
    await _reloadCalorieEntries();
  }

  Future<void> deleteCalorieEntry(String id) async {
    // Remove from local list
    _calorieEntries.removeWhere((entry) => entry.id == id);
    notifyListeners();

    // Delete from local DB and sync
    await _syncService.deleteCalorieEntry(id);
    
    // Reload from database to ensure persistence
    await _reloadCalorieEntries();
  }

  Future<void> deleteFocusSession(String id) async {
    print('🗑️ Deleting focus session: $id');
    
    // Remove from local list
    _focusSessions.removeWhere((session) => session.id == id);
    notifyListeners();

    // Delete from local DB and sync
    try {
      await _syncService.deleteFocusSession(id);
      print('✅ Focus session deleted from local DB');
      
      // Trigger sync to cloud if online
      if (_isOnline && _supabaseService.isAuthenticated) {
        _syncService.syncAllData();
      }
    } catch (e) {
      print('❌ Error deleting focus session: $e');
    }
  }

  Future<void> clearAllFocusSessions() async {
    print('🗑️ Clearing all focus sessions');
    
    // Clear local list
    _focusSessions.clear();
    notifyListeners();

    // Clear from local DB
    try {
      await _syncService.clearAllFocusSessions();
      print('✅ All focus sessions cleared');
    } catch (e) {
      print('❌ Error clearing focus sessions: $e');
    }
  }
  
  Future<void> _reloadFocusSessions() async {
    try {
      // Always load from local database first
      final localSessions = await _syncService.getFocusSessions();
      final localSessionsList = localSessions.map((s) => FocusSession(
        id: s['id'] as String,
        durationMinutes: s['duration_minutes'] as int,
        subjectTags: List<String>.from(s['subject_tags']),
        sessionDate: DateTime.parse(s['session_date'] as String),
        completed: s['completed'] as bool,
        focusMode: s['focus_mode'] as String? ?? 'normal',
        breakCount: s['break_count'] as int? ?? 0,
      )).toList();
      
      // If authenticated and online, also fetch from Supabase and merge
      if (_supabaseService.isAuthenticated && _isOnline) {
        try {
          final supabaseSessions = await _supabaseService.getFocusSessions();
          final supabaseSessionsList = supabaseSessions.map((s) => FocusSession(
            id: s['id'] as String,
            durationMinutes: s['duration_minutes'] as int,
            subjectTags: List<String>.from(s['subject_tags'] ?? []),
            sessionDate: DateTime.parse(s['session_date'] as String),
            completed: s['completed'] as bool? ?? true,
            focusMode: s['focus_mode'] as String? ?? 'normal',
            breakCount: s['break_count'] as int? ?? 0,
          )).toList();
          
          // Merge: use local sessions + any cloud sessions not in local
          final localIds = localSessionsList.map((s) => s.id).toSet();
          final cloudOnlySessions = supabaseSessionsList.where((s) => !localIds.contains(s.id)).toList();
          
          _focusSessions = [...localSessionsList, ...cloudOnlySessions];
          print('✅ Loaded ${localSessionsList.length} local + ${cloudOnlySessions.length} cloud-only focus sessions');
        } catch (e) {
          // If Supabase fails, just use local data
          _focusSessions = localSessionsList;
          print('⚠️ Supabase fetch failed, using ${localSessionsList.length} local sessions: $e');
        }
      } else {
        _focusSessions = localSessionsList;
        print('✅ Loaded ${_focusSessions.length} focus sessions from local DB');
      }
      
      // Sort by date descending
      _focusSessions.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
      notifyListeners();
    } catch (e) {
      print('❌ Error reloading focus sessions: $e');
    }
  }
  
  Future<void> _reloadCalorieEntries() async {
    try {
      // Try to fetch from Supabase if authenticated
      if (_supabaseService.isAuthenticated && _isOnline) {
        final supabaseEntries = await _supabaseService.getCalorieEntries();
        _calorieEntries = supabaseEntries.map((e) => CalorieEntry(
          id: e['id'] as String,
          type: e['type'] as String,
          description: e['description'] as String,
          amount: e['amount'] as int,
          entryDate: DateTime.parse(e['entry_date'] as String),
        )).toList();
        print('✅ Loaded ${_calorieEntries.length} calorie entries from Supabase');
      } else {
        // Fallback to local database
        final entries = await _syncService.getCalorieEntries();
        _calorieEntries = entries.map((e) => CalorieEntry(
          id: e['id'] as String,
          type: e['type'] as String,
          description: e['description'] as String,
          amount: e['amount'] as int,
          entryDate: DateTime.parse(e['entry_date'] as String),
        )).toList();
        print('✅ Loaded ${_calorieEntries.length} calorie entries from local DB');
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error reloading calorie entries: $e');
    }
  }

  int getTodayFocusMinutes() {
    final today = DateTime.now();
    return _focusSessions
        .where((s) => _isSameDay(s.sessionDate, today))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  int getTodayCaloriesBurned() {
    final today = DateTime.now();
    return _calorieEntries
        .where((e) => _isSameDay(e.entryDate, today) && e.type == 'burn')
        .fold(0, (sum, e) => sum + e.amount);
  }

  int getTodayCaloriesIn() {
    final today = DateTime.now();
    return _calorieEntries
        .where((e) => _isSameDay(e.entryDate, today) && e.type == 'food')
        .fold(0, (sum, e) => sum + e.amount);
  }

  // History helpers
  Map<String, dynamic> getMonthData(int year, int month) {
    final sessions = _focusSessions.where((s) =>
        s.sessionDate.year == year && s.sessionDate.month == month);
    final entries = _calorieEntries.where((e) =>
        e.entryDate.year == year && e.entryDate.month == month && e.type == 'burn');
    
    return {
      'focusMinutes': sessions.fold(0, (sum, s) => sum + s.durationMinutes),
      'caloriesBurned': entries.fold(0, (sum, e) => sum + e.amount),
    };
  }

  Map<String, dynamic> getDayData(DateTime date) {
    final sessions = _focusSessions.where((s) => _isSameDay(s.sessionDate, date)).toList();
    final entries = _calorieEntries.where((e) => _isSameDay(e.entryDate, date)).toList();
    final focusMinutes = sessions.fold(0, (sum, s) => sum + s.durationMinutes);
    final caloriesBurned = entries.where((e) => e.type == 'burn').fold(0, (sum, e) => sum + e.amount);
    
    return {
      'focusMinutes': focusMinutes,
      'caloriesBurned': caloriesBurned,
      'sessions': sessions,
      'entries': entries,
    };
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Friend methods
  Future<void> loadFriends() async {
    if (!_supabaseService.isAuthenticated) {
      print('❌ Not authenticated - cannot load friends');
      return;
    }

    try {
      print('👥 Loading friends from Supabase...');
      final friendsData = await _supabaseService.getFriends();
      
      // First, load friends with basic info (fast)
      _friends.clear();
      final friendIds = <String>[];
      
      for (final data in friendsData) {
        final friendProfile = data['friend'] as Map<String, dynamic>?;
        if (friendProfile != null) {
          final friendId = friendProfile['id'] as String;
          friendIds.add(friendId);
          
          // Check real-time presence first, then fall back to database
          final presence = _presenceService.getUserPresence(friendId);
          final lastSeen = friendProfile['last_seen'] as String? ?? friendProfile['last_active_date'] as String?;
          final status = presence?.status ?? 
              _presenceService.getFriendStatus(friendId, lastSeen);
          
          // Add friend with 0 stats initially (will update later)
          _friends.add(Friend(
            id: friendId,
            name: friendProfile['full_name'] as String? ?? 'Unknown',
            avatarUrl: friendProfile['avatar_url'] as String? ?? '',
            status: status,
            currentActivity: presence?.activity ?? friendProfile['current_activity'] as String?,
            focusMinutes: presence?.focusMinutes,
            weeklyFocusHours: 0,
            weeklyCaloriesBurned: 0,
          ));
        }
      }
      
      // Notify immediately with basic friend info
      notifyListeners();
      print('✅ Loaded ${_friends.length} friends (basic info)');
      
      // Then fetch stats for all friends in parallel (background)
      if (friendIds.isNotEmpty) {
        _loadFriendStatsInBackground(friendIds);
      }
    } catch (e) {
      print('❌ Error loading friends: $e');
    }
  }
  
  /// Load friend stats in background without blocking UI
  Future<void> _loadFriendStatsInBackground(List<String> friendIds) async {
    try {
      // Fetch all friend stats in parallel
      final statsFutures = friendIds.map((id) => _supabaseService.getFriendWeeklyStats(id));
      final allStats = await Future.wait(statsFutures);
      
      // Update friends with stats
      for (int i = 0; i < _friends.length && i < allStats.length; i++) {
        final friend = _friends[i];
        final stats = allStats[i];
        final weeklyFocusHours = ((stats['focusMinutes'] as int? ?? 0) / 60).round();
        final weeklyCaloriesBurned = stats['caloriesBurned'] as int? ?? 0;
        
        _friends[i] = Friend(
          id: friend.id,
          name: friend.name,
          avatarUrl: friend.avatarUrl,
          status: friend.status,
          currentActivity: friend.currentActivity,
          focusMinutes: friend.focusMinutes,
          weeklyFocusHours: weeklyFocusHours,
          weeklyCaloriesBurned: weeklyCaloriesBurned,
        );
      }
      
      notifyListeners();
      print('📊 Updated friend stats');
    } catch (e) {
      print('⚠️ Error loading friend stats: $e');
    }
  }

  String _getOnlineStatus(String? lastActiveDate) {
    if (lastActiveDate == null) return 'offline';
    
    final lastActive = DateTime.tryParse(lastActiveDate);
    if (lastActive == null) return 'offline';
    
    final now = DateTime.now();
    final diff = now.difference(lastActive);
    
    // Strict check: only online if seen in last 30 seconds
    if (diff.inSeconds < 30) return 'online';
    return 'offline';
  }

  Future<Map<String, dynamic>?> searchUserByUniqueId(String uniqueId) async {
    if (!_supabaseService.isAuthenticated) {
      throw Exception('Not authenticated');
    }
    
    print('🔍 Searching for user with ID: $uniqueId');
    final user = await _supabaseService.searchUserByUniqueId(uniqueId);
    
    if (user == null) {
      print('❌ User not found');
      throw Exception('User not found');
    }
    
    print('✅ Found user: ${user['full_name']}');
    return user;
  }

  Future<void> addFriend(String friendId) async {
    if (!_supabaseService.isAuthenticated) {
      throw Exception('Not authenticated');
    }
    
    // Check if already friends
    if (_friends.any((f) => f.id == friendId)) {
      throw Exception('Already friends with this user');
    }
    
    // Check if trying to add self
    if (friendId == _user?.id) {
      throw Exception('Cannot add yourself as a friend');
    }
    
    print('➕ Adding friend (bidirectional): $friendId');
    await _supabaseService.addFriend(friendId);
    
    // Reload friends list
    await loadFriends();
    print('✅ Friend added successfully');
  }

  /// Remove a friend - removes bidirectional friendship
  /// Either user can remove the other
  Future<void> removeFriend(String friendId) async {
    if (!_supabaseService.isAuthenticated) {
      throw Exception('Not authenticated');
    }
    
    print('🗑️ Removing friend: $friendId');
    await _supabaseService.removeFriend(friendId);
    
    // Remove from local list
    _friends.removeWhere((f) => f.id == friendId);
    notifyListeners();
    
    print('✅ Friend removed successfully');
  }

  Future<void> addFriendByUniqueId(String uniqueId) async {
    // First search for the user
    final user = await searchUserByUniqueId(uniqueId);
    if (user == null) {
      throw Exception('User not found');
    }
    
    // Then add as friend
    await addFriend(user['id'] as String);
  }

  // Logout
  Future<void> logout() async {
    print('👋 Logging out user');
    
    // Cleanup presence (stop timers and set offline status)
    await _presenceService.cleanup();
    
    // Sign out from Supabase
    await _supabaseService.signOut();
    
    // Clear all local data
    _user = null;
    _focusSessions.clear();
    _calorieEntries.clear();
    _friends.clear();
    _habits.clear();
    _habitLogs.clear();
    
    // Clear local database
    await _syncService.clearAllData();
    
    print('✅ Logout complete');
    notifyListeners();
  }

  Future<void> refreshUserData() async {
    try {
      if (_supabaseService.isAuthenticated) {
        final profile = await _supabaseService.getUserProfile();
        if (profile != null) {
          _user = User(
            id: profile['id'] as String,
            uniqueId: profile['unique_id'] as String?,
            fullName: profile['full_name'] as String,
            email: profile['email'] as String,
            avatarUrl: profile['avatar_url'] as String?,
            dailyFocusGoal: profile['daily_focus_goal'] as int? ?? 180,
            dailyCalorieGoal: profile['daily_calorie_goal'] as int? ?? 2000,
            notificationsEnabled: profile['notifications_enabled'] as bool? ?? true,
            weeklyReportEnabled: profile['weekly_report_enabled'] as bool? ?? false,
            currentStreak: profile['current_streak'] as int? ?? 0,
            longestStreak: profile['longest_streak'] as int? ?? 0,
          );
          
          // Notify immediately with user profile
          notifyListeners();
          
          // Load focus sessions and calorie entries in parallel
          await Future.wait([
            _reloadFocusSessions(),
            _reloadCalorieEntries(),
          ]);
          
          // Notify with sessions data
          notifyListeners();
          
          // Load friends in background (don't block UI)
          loadFriends(); // No await - runs in background
          
          // Set user as online
          _presenceService.setOnline(); // No await
        }
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  /// Called when user starts a focus session
  Future<void> startFocusing({required String subject, required int durationMinutes}) async {
    await _presenceService.setFocusing(subject: subject, minutes: durationMinutes);
  }

  /// Called when user stops focusing (completes or cancels session)
  Future<void> stopFocusing() async {
    await _presenceService.setOnline();
  }

  /// Reconnect presence service (call when app comes to foreground)
  Future<void> reconnectPresence() async {
    await _presenceService.reconnect();
  }

  /// Disconnect presence service (call when app goes to background or logs out)
  Future<void> disconnectPresence() async {
    await _presenceService.setOffline();
    await _presenceService.cleanup();
  }

  // ========================
  // HABIT TRACKER METHODS
  // ========================

  /// Load habits for the selected month
  Future<void> loadHabits() async {
    _isLoadingHabits = true;
    notifyListeners();

    try {
      final monthKey = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
      final data = await _supabaseService.getHabits(month: monthKey);
      
      _habits = data.map((json) => Habit.fromJson(json)).toList();
      
      // Load logs for all habits in this month
      await _loadHabitLogsForMonth();
    } catch (e) {
      print('❌ Error loading habits: $e');
    }

    _isLoadingHabits = false;
    notifyListeners();
  }

  /// Load habit logs for the selected month
  Future<void> _loadHabitLogsForMonth() async {
    if (_habits.isEmpty) return;

    final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    try {
      final data = await _supabaseService.getHabitLogs(
        startDate: startDate,
        endDate: endDate,
      );

      // Group logs by habit_id
      _habitLogs.clear();
      for (final json in data) {
        final log = HabitLog.fromJson(json);
        _habitLogs[log.habitId] ??= [];
        _habitLogs[log.habitId]!.add(log);
      }
    } catch (e) {
      print('❌ Error loading habit logs: $e');
    }
  }

  /// Change selected month
  Future<void> changeMonth(DateTime newMonth) async {
    _selectedMonth = newMonth;
    await loadHabits();
  }

  /// Go to previous month
  Future<void> previousMonth() async {
    final newMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    await changeMonth(newMonth);
  }

  /// Go to next month
  Future<void> nextMonth() async {
    final newMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    await changeMonth(newMonth);
  }

  /// Add a new habit
  Future<void> addHabit({
    required String name,
    String? description,
    String frequency = 'daily',
    int targetCount = 30,
    String color = '#ff6b35',
    String icon = '✓',
  }) async {
    try {
      final monthKey = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
      
      final data = await _supabaseService.addHabit(
        name: name,
        description: description,
        frequency: frequency,
        targetCount: targetCount,
        color: color,
        icon: icon,
        activeMonths: [monthKey],
      );

      final newHabit = Habit.fromJson(data);
      _habits.add(newHabit);
      notifyListeners();
      
      print('✅ Habit added: ${newHabit.name}');
    } catch (e) {
      print('❌ Error adding habit: $e');
      rethrow;
    }
  }

  /// Update habit
  Future<void> updateHabit(String habitId, Map<String, dynamic> updates) async {
    try {
      await _supabaseService.updateHabit(habitId, updates);
      
      // Update local list
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        final oldHabit = _habits[index];
        _habits[index] = oldHabit.copyWith(
          name: updates['name'] ?? oldHabit.name,
          description: updates['description'] ?? oldHabit.description,
          color: updates['color'] ?? oldHabit.color,
          icon: updates['icon'] ?? oldHabit.icon,
        );
        notifyListeners();
      }
      
      print('✅ Habit updated');
    } catch (e) {
      print('❌ Error updating habit: $e');
      rethrow;
    }
  }

  /// Delete habit (archive)
  Future<void> deleteHabit(String habitId) async {
    try {
      await _supabaseService.deleteHabit(habitId);
      _habits.removeWhere((h) => h.id == habitId);
      _habitLogs.remove(habitId);
      notifyListeners();
      
      print('✅ Habit deleted');
    } catch (e) {
      print('❌ Error deleting habit: $e');
      rethrow;
    }
  }

  /// Toggle habit completion for a specific date
  Future<void> toggleHabitLog({
    required String habitId,
    required DateTime date,
    bool? completed,
    int? count,
    String? notes,
  }) async {
    try {
      final data = await _supabaseService.toggleHabitLog(
        habitId: habitId,
        date: date,
        completed: completed,
        count: count,
        notes: notes,
      );

      final log = HabitLog.fromJson(data);
      
      // Update local logs
      _habitLogs[habitId] ??= [];
      final existingIndex = _habitLogs[habitId]!.indexWhere(
        (l) => l.dateKey == log.dateKey,
      );
      
      if (existingIndex != -1) {
        _habitLogs[habitId]![existingIndex] = log;
      } else {
        _habitLogs[habitId]!.add(log);
      }
      
      notifyListeners();
      print('✅ Habit log toggled for ${log.dateKey}');
    } catch (e) {
      print('❌ Error toggling habit log: $e');
      rethrow;
    }
  }

  /// Get completion percentage for a habit in the current month
  int getHabitCompletionPercentage(String habitId) {
    final logs = _habitLogs[habitId] ?? [];
    if (logs.isEmpty) return 0;
    
    final completedCount = logs.where((log) => log.completed).length;
    final totalDays = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    
    return ((completedCount / totalDays) * 100).round();
  }

  /// Get friend's habits (read-only)
  Future<List<Habit>> getFriendHabits(String friendId) async {
    try {
      final monthKey = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
      final data = await _supabaseService.getFriendHabits(friendId, month: monthKey);
      return data.map((json) => Habit.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error loading friend habits: $e');
      return [];
    }
  }

  /// Get friend's habit logs (read-only)
  Future<List<HabitLog>> getFriendHabitLogs(String friendId, DateTime startDate, DateTime endDate) async {
    try {
      final data = await _supabaseService.getFriendHabitLogs(
        friendId: friendId,
        startDate: startDate,
        endDate: endDate,
      );
      return data.map((json) => HabitLog.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error loading friend habit logs: $e');
      return [];
    }
  }
}
