# AN Life Tracker - Supabase Integration Guide

## ✅ Completed Changes

1. **Break Timer**
   - Added 2-minute break option
   - Fixed break timer not running issue

2. **Navigation Updates**
   - Focus icon: Brain (🧠) with lavender color (#B4A7D6)
   - Friends icon: Green color (#4ADE80)
   - Changed "Rank" to "Leaderboard"

3. **Home Page**
   - Removed fake graphs
   - Shows only online friends
   - Brain icon appears for focusing friends

4. **Leaderboard**
   - Bigger golden heading (32px, #FFD700 color)
   - Golden trophy cup for 1st place
   - Silver trophy cup for 2nd place
   - Bronze trophy cup for 3rd place
   - Removed Ghost Mode
   - Privacy controls work properly (Hide Focus/Hide Calories)

## 🚀 Next Steps - Supabase Setup

### Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Create a new project
3. Note your **Project URL** and **Anon Key**

### Step 2: Run Database Schema

1. In Supabase Dashboard, go to SQL Editor
2. Open the file `supabase_schema.sql` from your project root
3. Copy and paste all the SQL code
4. Run the query to create all tables, policies, and functions

### Step 3: Configure Your App

1. Open `lib/core/services/supabase_service.dart`
2. Replace:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
   ```
   With your actual Supabase credentials

### Step 4: Update main.dart

Add Supabase initialization in `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/app_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'features/navigation/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'AN Life Tracker',
        theme: AppTheme.lightTheme,
        home: const MainNavigation(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
```

## 📝 TODO: Implementations Needed

### 1. Add Friend Feature (High Priority)

Create `lib/features/friends/widgets/add_friend_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class AddFriendDialog extends StatefulWidget {
  const AddFriendDialog({super.key});

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _foundUser;

  Future<void> _searchUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foundUser = null;
    });

    try {
      final user = await SupabaseService().searchUserByUniqueId(_controller.text.trim());
      setState(() {
        _foundUser = user;
        if (user == null) {
          _errorMessage = 'User not found';
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addFriend() async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService().addFriend(_foundUser!['id']);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend added successfully! 🎉')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error adding friend: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ADE80).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add, color: Color(0xFF4ADE80)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add Friend',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter unique ID',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onSubmitted: (_) => _searchUser(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            if (_foundUser != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      child: Text(_foundUser!['full_name'][0]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _foundUser!['full_name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'ID: ${_foundUser!['unique_id']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.foreground.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_foundUser == null ? _searchUser : _addFriend),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADE80),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_foundUser == null ? 'Search' : 'Add Friend'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**Add to FriendsPage**: Add a floating action button to open the AddFriendDialog.

### 2. History Feature (Settings Page)

Create `lib/features/profile/history_page.dart` with:
- Year selector at top
- Months grid view showing mini graphs for each month
- Click month → Show days of that month
- Click day → Show detailed breakdown:
  - Focus sessions (time, subject)
  - Calorie intake
  - Calorie burn activities
- Beautiful minimal UI with subtle colors
- Less blue, more greens, purples, and neutral tones

### 3. Update AppProvider to Use Supabase

Modify `lib/core/providers/app_provider.dart`:
- Replace `_loadMockData()` with `loadDataFromSupabase()`
- Add methods that call SupabaseService
- Listen to real-time updates
- Sync local state with Supabase

### 4. Add Authentication

Create login/signup screens:
- `lib/features/auth/login_page.dart`
- `lib/features/auth/signup_page.dart`
- Use SupabaseService auth methods

### 5. Profile Page Updates

- Show user's unique ID prominently
- Add copy button for unique ID
- Remove daily goals section
- Add "View History" button → Opens HistoryPage

## 🎨 UI Color Guidelines

- **Primary Actions**: Green (#4ADE80)
- **Focus/Brain**: Lavender (#B4A7D6)
- **Warnings**: Amber
- **Errors**: Red
- **Success**: Green
- **Neutral Backgrounds**: Light gray, off-white
- **Minimize Blue**: Use only for info/secondary actions

## 📊 Database Schema Summary

**Tables:**
- `profiles` - User data with unique_id, privacy settings
- `focus_sessions` - Study sessions with duration, subjects
- `calorie_entries` - Food/burn entries
- `friendships` - Friend connections

**Key Features:**
- Row Level Security (RLS) enabled
- Automatic profile creation on signup
- Privacy controls for leaderboard
- Efficient indexing for queries

## 🔧 Hot Reload Note

After making changes, press `r` in the terminal to hot reload the app!

## ⚠️ Important Notes

1. **Replace Supabase credentials** before running
2. **Run SQL schema** in Supabase dashboard
3. **Enable authentication** in Supabase (Email/Password)
4. **Test thoroughly** after each integration step

## 📱 Current Status

✅ UI Updates Complete
✅ Supabase Package Added
✅ Service Layer Created
✅ Database Schema Ready
⏳ Authentication (Todo)
⏳ Add Friend Dialog (Todo)
⏳ History Feature (Todo)
⏳ AppProvider Migration (Todo)
