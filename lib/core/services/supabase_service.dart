import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://bqiqwvcwoclgntofggtc.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxaXF3dmN3b2NsZ250b2ZnZ3RjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY5OTc3ODQsImV4cCI6MjA4MjU3Mzc4NH0.0NY0KDMsa6B6DjoXP6Ac2xXX4iQVYINu5qwcAB6YSiQ';

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Auth helpers
  User? get currentUser => client.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  // Sign up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    print('🔐 Attempting sign up for: $email');
    
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      
      print('✅ Sign up response received');
      print('   User ID: ${response.user?.id}');
      print('   User Email: ${response.user?.email}');
      print('   Session: ${response.session != null ? "Active" : "None"}');
      
      // Note: Profile creation is now handled by the database trigger
      // No need to manually insert into profiles table
      
      return response;
    } catch (e) {
      print('❌ Sign up error: $e');
      print('   Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  String _generateUniqueId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(8, (index) => chars[(random + index) % chars.length]).join();
  }

  // Sign in
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    print('🔐 Attempting sign in for: $email');
    
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      print('✅ Sign in response received');
      print('   User ID: ${response.user?.id}');
      print('   Session: ${response.session != null ? "Active" : "None"}');
      
      return response;
    } catch (e) {
      print('❌ Sign in error: $e');
      print('   Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Focus Sessions
  Future<List<Map<String, dynamic>>> getFocusSessions() async {
    final response = await client
        .from('focus_sessions')
        .select()
        .eq('user_id', currentUserId!)
        .order('session_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addFocusSession(Map<String, dynamic> session) async {
    await client.from('focus_sessions').insert({
      ...session,
      'user_id': currentUserId,
    });
    
    // Update last active date and check streak
    await _updateActivityAndStreak();
  }

  // Basic version without extra columns for backwards compatibility
  Future<void> addFocusSessionBasic(Map<String, dynamic> session) async {
    await client.from('focus_sessions').insert({
      'id': session['id'],
      'user_id': currentUserId,
      'duration_minutes': session['duration_minutes'],
      'subject_tags': session['subject_tags'],
      'session_date': session['session_date'],
      'completed': session['completed'],
    });
    
    await _updateActivityAndStreak();
  }

  // Calorie Entries
  Future<List<Map<String, dynamic>>> getCalorieEntries() async {
    final response = await client
        .from('calorie_entries')
        .select()
        .eq('user_id', currentUserId!)
        .order('entry_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addCalorieEntry(Map<String, dynamic> entry) async {
    await client.from('calorie_entries').insert({
      ...entry,
      'user_id': currentUserId,
    });
  }

  Future<void> deleteCalorieEntry(String id) async {
    await client.from('calorie_entries').delete().eq('id', id);
  }

  Future<void> deleteFocusSession(String id) async {
    await client.from('focus_sessions').delete().eq('id', id);
  }

  Future<void> clearAllFocusSessions() async {
    await client.from('focus_sessions').delete().eq('user_id', currentUserId!);
  }

  // Friends
  Future<List<Map<String, dynamic>>> getFriends() async {
    final response = await client
        .from('friendships')
        .select('*, friend:profiles!friendships_friend_id_fkey(*)')
        .eq('user_id', currentUserId!)
        .eq('status', 'accepted');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getOnlineFriends() async {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    final response = await client
        .from('friendships')
        .select('*, friend:profiles!friendships_friend_id_fkey(*)')
        .eq('user_id', currentUserId!)
        .eq('status', 'accepted')
        .gte('friend.last_active_date', fiveMinutesAgo.toIso8601String());
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> searchUserByUniqueId(String uniqueId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('unique_id', uniqueId)
        .maybeSingle();
    return response;
  }

  /// Add friend - creates bidirectional friendship
  /// When user A adds user B, both A->B and B->A friendships are created
  Future<void> addFriend(String friendId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');
    
    // Check if friendship already exists in either direction
    final existingForward = await client
        .from('friendships')
        .select()
        .eq('user_id', userId)
        .eq('friend_id', friendId)
        .maybeSingle();
    
    final existingReverse = await client
        .from('friendships')
        .select()
        .eq('user_id', friendId)
        .eq('friend_id', userId)
        .maybeSingle();
    
    // Create forward friendship if doesn't exist
    if (existingForward == null) {
      await client.from('friendships').insert({
        'user_id': userId,
        'friend_id': friendId,
        'status': 'accepted',
      });
      print('✅ Created friendship: $userId -> $friendId');
    }
    
    // Create reverse friendship if doesn't exist (bidirectional)
    if (existingReverse == null) {
      await client.from('friendships').insert({
        'user_id': friendId,
        'friend_id': userId,
        'status': 'accepted',
      });
      print('✅ Created reverse friendship: $friendId -> $userId');
    }
  }

  /// Remove friend - removes bidirectional friendship
  /// Either user can remove the friendship
  Future<void> removeFriend(String friendId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not authenticated');
    
    // Remove forward friendship (user -> friend)
    await client
        .from('friendships')
        .delete()
        .eq('user_id', userId)
        .eq('friend_id', friendId);
    
    // Remove reverse friendship (friend -> user)
    await client
        .from('friendships')
        .delete()
        .eq('user_id', friendId)
        .eq('friend_id', userId);
    
    print('🗑️ Removed friendship between $userId and $friendId');
  }

  /// Check if user is friends with another user
  Future<bool> isFriendWith(String friendId) async {
    final userId = currentUserId;
    if (userId == null) return false;
    
    final friendship = await client
        .from('friendships')
        .select()
        .eq('user_id', userId)
        .eq('friend_id', friendId)
        .eq('status', 'accepted')
        .maybeSingle();
    
    return friendship != null;
  }

  // User Profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', currentUserId!)
        .maybeSingle();
    return response;
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    await client
        .from('profiles')
        .update(data)
        .eq('id', currentUserId!);
  }

  Future<void> updateUserName(String fullName) async {
    await client
        .from('profiles')
        .update({'full_name': fullName})
        .eq('id', currentUserId!);
  }

  Future<void> updateUserAvatar(String avatarUrl) async {
    await client
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', currentUserId!);
  }

  Future<void> updateNotificationSettings({
    required bool notificationsEnabled,
    required bool weeklyReportEnabled,
  }) async {
    await client
        .from('profiles')
        .update({
          'notifications_enabled': notificationsEnabled,
          'weekly_report_enabled': weeklyReportEnabled,
        })
        .eq('id', currentUserId!);
  }

  // Streak Management
  Future<void> _updateActivityAndStreak() async {
    final profile = await getUserProfile();
    if (profile == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final lastActiveStr = profile['last_active_date'] as String?;
    if (lastActiveStr == null) {
      // First time, start streak
      await client.from('profiles').update({
        'current_streak': 1,
        'longest_streak': 1,
        'last_active_date': now.toIso8601String(),
      }).eq('id', currentUserId!);
      return;
    }

    final lastActive = DateTime.parse(lastActiveStr);
    final lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
    
    final daysDiff = today.difference(lastActiveDay).inDays;
    
    int currentStreak = profile['current_streak'] ?? 0;
    int longestStreak = profile['longest_streak'] ?? 0;

    if (daysDiff == 0) {
      // Same day, just update timestamp
      await client.from('profiles').update({
        'last_active_date': now.toIso8601String(),
      }).eq('id', currentUserId!);
    } else if (daysDiff == 1) {
      // Consecutive day, increment streak
      currentStreak++;
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
      await client.from('profiles').update({
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_active_date': now.toIso8601String(),
      }).eq('id', currentUserId!);
    } else {
      // Streak broken, reset to 1
      await client.from('profiles').update({
        'current_streak': 1,
        'last_active_date': now.toIso8601String(),
      }).eq('id', currentUserId!);
    }
  }

  Future<int> getCurrentStreak() async {
    final profile = await getUserProfile();
    if (profile == null) return 0;
    
    // Check if streak should be reset
    final lastActiveStr = profile['last_active_date'] as String?;
    if (lastActiveStr != null) {
      final lastActive = DateTime.parse(lastActiveStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
      
      final daysDiff = today.difference(lastActiveDay).inDays;
      
      if (daysDiff > 1) {
        // Streak expired, reset it
        await client.from('profiles').update({
          'current_streak': 0,
        }).eq('id', currentUserId!);
        return 0;
      }
    }
    
    return profile['current_streak'] ?? 0;
  }

  // Weekly Report
  Future<void> requestWeeklyReport() async {
    // This will trigger an edge function in Supabase to send email
    await client.functions.invoke('send-weekly-report', body: {
      'user_id': currentUserId,
    });
  }

  // Update user status
  Future<void> updateUserStatus(String status) async {
    await client
        .from('profiles')
        .update({
          'status': status,
          'last_active_date': DateTime.now().toIso8601String(),
        })
        .eq('id', currentUserId!);
  }

  // Get friend's focus sessions
  Future<List<Map<String, dynamic>>> getFriendFocusSessions(String friendId) async {
    final response = await client
        .from('focus_sessions')
        .select()
        .eq('user_id', friendId)
        .order('session_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get friend's calorie entries
  Future<List<Map<String, dynamic>>> getFriendCalorieEntries(String friendId) async {
    final response = await client
        .from('calorie_entries')
        .select()
        .eq('user_id', friendId)
        .order('entry_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get friend's weekly stats
  Future<Map<String, dynamic>> getFriendWeeklyStats(String friendId) async {
    final now = DateTime.now();
    // Start of week (Monday at 00:00:00)
    final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    
    int totalFocusMinutes = 0;
    int totalCaloriesBurned = 0;
    
    try {
      // Get focus sessions this week
      final focusSessions = await client
          .from('focus_sessions')
          .select()
          .eq('user_id', friendId)
          .gte('session_date', weekStart.toIso8601String());
      
      totalFocusMinutes = (focusSessions as List).fold<int>(
        0,
        (sum, session) => sum + (session['duration_minutes'] as int? ?? 0),
      );
      print('📊 Friend $friendId focus: ${focusSessions.length} sessions, $totalFocusMinutes minutes');
    } catch (e) {
      print('⚠️ Error getting friend focus sessions: $e');
    }
    
    try {
      // Get calories burned this week
      final calorieEntries = await client
          .from('calorie_entries')
          .select()
          .eq('user_id', friendId)
          .eq('type', 'burn')
          .gte('entry_date', weekStart.toIso8601String());
      
      totalCaloriesBurned = (calorieEntries as List).fold<int>(
        0,
        (sum, entry) => sum + (entry['amount'] as int? ?? 0),
      );
      print('📊 Friend $friendId calories: ${calorieEntries.length} entries, $totalCaloriesBurned burned');
    } catch (e) {
      print('⚠️ Error getting friend calorie entries: $e');
    }
    
    return {
      'focusMinutes': totalFocusMinutes,
      'focusHours': totalFocusMinutes / 60,
      'caloriesBurned': totalCaloriesBurned,
    };
  }

  // Send notification to friend
  Future<void> sendNotification({
    required String receiverId,
    required String message,
  }) async {
    await client.from('notifications').insert({
      'sender_id': currentUserId,
      'receiver_id': receiverId,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Get unread notifications
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    final response = await client
        .from('notifications')
        .select('*, sender:profiles!sender_id(id, full_name, avatar_url)')
        .eq('receiver_id', currentUserId!)
        .isFilter('read_at', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
  }

  // Get all notifications (read and unread)
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final response = await client
        .from('notifications')
        .select('*, sender:profiles!sender_id(id, full_name, avatar_url)')
        .eq('receiver_id', currentUserId!)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  // ========================
  // HABIT TRACKER METHODS
  // ========================

  // Get user's habits for a specific month
  Future<List<Map<String, dynamic>>> getHabits({String? month}) async {
    // Note: Month filtering done in AppProvider since array operators vary by Supabase version
    final query = client
        .from('habits')
        .select()
        .eq('user_id', currentUserId!)
        .eq('is_archived', false)
        .order('created_at', ascending: true);

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  // Get friend's habits (read-only)
  Future<List<Map<String, dynamic>>> getFriendHabits(String friendId, {String? month}) async {
    // Note: Month filtering done in UI layer
    final query = client
        .from('habits')
        .select()
        .eq('user_id', friendId)
        .eq('is_archived', false)
        .order('created_at', ascending: true);

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  // Add a new habit
  Future<Map<String, dynamic>> addHabit({
    required String name,
    String? description,
    String frequency = 'daily',
    int targetCount = 30,
    String color = '#ff6b35',
    String icon = '✓',
    List<String>? activeMonths,
  }) async {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    final response = await client
        .from('habits')
        .insert({
          'user_id': currentUserId,
          'name': name,
          'description': description,
          'frequency': frequency,
          'target_count': targetCount,
          'color': color,
          'icon': icon,
          'active_months': activeMonths ?? [currentMonth],
        })
        .select()
        .single();

    return response as Map<String, dynamic>;
  }

  // Update habit
  Future<void> updateHabit(String habitId, Map<String, dynamic> updates) async {
    await client
        .from('habits')
        .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', habitId);
  }

  // Delete habit (soft delete by archiving)
  Future<void> deleteHabit(String habitId) async {
    await client
        .from('habits')
        .update({'is_archived': true, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', habitId);
  }

  // Get habit logs for a specific date range
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

    final response = await query.order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get friend's habit logs (read-only)
  Future<List<Map<String, dynamic>>> getFriendHabitLogs({
    required String friendId,
    required DateTime startDate,
    required DateTime endDate,
    String? habitId,
  }) async {
    var query = client
        .from('habit_logs')
        .select()
        .eq('user_id', friendId)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    if (habitId != null) {
      query = query.eq('habit_id', habitId);
    }

    final response = await query.order('date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Toggle habit log (mark as complete/incomplete)
  Future<Map<String, dynamic>> toggleHabitLog({
    required String habitId,
    required DateTime date,
    bool? completed,
    int? count,
    String? notes,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];

    // Check if log exists
    final existing = await client
        .from('habit_logs')
        .select()
        .eq('user_id', currentUserId!)
        .eq('habit_id', habitId)
        .eq('date', dateStr)
        .maybeSingle();

    if (existing != null) {
      // Update existing log
      final response = await client
          .from('habit_logs')
          .update({
            if (completed != null) 'completed': completed,
            if (count != null) 'count': count,
            if (notes != null) 'notes': notes,
          })
          .eq('id', existing['id'])
          .select()
          .single();
      return response as Map<String, dynamic>;
    } else {
      // Create new log
      final response = await client
          .from('habit_logs')
          .insert({
            'user_id': currentUserId,
            'habit_id': habitId,
            'date': dateStr,
            'completed': completed ?? true,
            'count': count ?? 1,
            'notes': notes,
          })
          .select()
          .single();
      return response as Map<String, dynamic>;
    }
  }

  // Get weekly habit stats for leaderboard
  Future<Map<String, dynamic>> getWeeklyHabitStats(String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final logs = await client
        .from('habit_logs')
        .select('completed')
        .eq('user_id', userId)
        .gte('date', weekStart.toIso8601String().split('T')[0])
        .lte('date', weekEnd.toIso8601String().split('T')[0]);

    final completedCount = (logs as List).where((log) => log['completed'] == true).length;
    final totalCount = logs.length;
    final completionRate = totalCount > 0 ? (completedCount / totalCount * 100).round() : 0;

    return {
      'completed_count': completedCount,
      'total_count': totalCount,
      'completion_rate': completionRate,
    };
  }
}
