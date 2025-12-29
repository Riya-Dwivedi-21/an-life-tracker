-- ================================================
-- AN LIFE TRACKER - COMPLETE DATABASE SETUP
-- Copy ALL of this code and run in Supabase SQL Editor
-- ================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================
-- 1. PROFILES TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  unique_id TEXT UNIQUE NOT NULL DEFAULT (substring(md5(random()::text) from 1 for 8)),
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  avatar_url TEXT,
  daily_focus_goal INTEGER DEFAULT 180,
  daily_calorie_goal INTEGER DEFAULT 2000,
  notifications_enabled BOOLEAN DEFAULT TRUE,
  weekly_report_enabled BOOLEAN DEFAULT FALSE,
  hide_focus BOOLEAN DEFAULT FALSE,
  hide_calories BOOLEAN DEFAULT FALSE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_active_date TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'focusing')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- 2. FOCUS SESSIONS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS focus_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  duration_minutes INTEGER NOT NULL,
  subject_tags TEXT[] DEFAULT '{}',
  session_date TIMESTAMP WITH TIME ZONE NOT NULL,
  completed BOOLEAN DEFAULT TRUE,
  synced BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- 3. CALORIE ENTRIES TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS calorie_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('food', 'burn')),
  description TEXT NOT NULL,
  amount INTEGER NOT NULL,
  entry_date TIMESTAMP WITH TIME ZONE NOT NULL,
  synced BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- 4. FRIENDSHIPS TABLE
-- ================================================
CREATE TABLE IF NOT EXISTS friendships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  friend_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'accepted' CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);

-- ================================================
-- 5. INDEXES FOR PERFORMANCE
-- ================================================
CREATE INDEX IF NOT EXISTS idx_focus_sessions_user_date ON focus_sessions(user_id, session_date DESC);
CREATE INDEX IF NOT EXISTS idx_focus_sessions_synced ON focus_sessions(synced) WHERE synced = FALSE;
CREATE INDEX IF NOT EXISTS idx_calorie_entries_user_date ON calorie_entries(user_id, entry_date DESC);
CREATE INDEX IF NOT EXISTS idx_calorie_entries_synced ON calorie_entries(synced) WHERE synced = FALSE;
CREATE INDEX IF NOT EXISTS idx_friendships_user ON friendships(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_unique_id ON profiles(unique_id);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);
CREATE INDEX IF NOT EXISTS idx_profiles_last_active ON profiles(last_active_date);

-- ================================================
-- 6. ROW LEVEL SECURITY (RLS) - ENABLE
-- ================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE focus_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE calorie_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- ================================================
-- 7. PROFILES POLICIES
-- ================================================
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Create new policies
CREATE POLICY "Users can view all profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ================================================
-- 8. FOCUS SESSIONS POLICIES
-- ================================================
DROP POLICY IF EXISTS "Users can view own focus sessions" ON focus_sessions;
DROP POLICY IF EXISTS "Users can insert own focus sessions" ON focus_sessions;
DROP POLICY IF EXISTS "Users can update own focus sessions" ON focus_sessions;
DROP POLICY IF EXISTS "Users can delete own focus sessions" ON focus_sessions;

CREATE POLICY "Users can view own focus sessions" ON focus_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own focus sessions" ON focus_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own focus sessions" ON focus_sessions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own focus sessions" ON focus_sessions FOR DELETE USING (auth.uid() = user_id);

-- ================================================
-- 9. CALORIE ENTRIES POLICIES
-- ================================================
DROP POLICY IF EXISTS "Users can view own calorie entries" ON calorie_entries;
DROP POLICY IF EXISTS "Users can insert own calorie entries" ON calorie_entries;
DROP POLICY IF EXISTS "Users can update own calorie entries" ON calorie_entries;
DROP POLICY IF EXISTS "Users can delete own calorie entries" ON calorie_entries;

CREATE POLICY "Users can view own calorie entries" ON calorie_entries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own calorie entries" ON calorie_entries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own calorie entries" ON calorie_entries FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own calorie entries" ON calorie_entries FOR DELETE USING (auth.uid() = user_id);

-- ================================================
-- 10. FRIENDSHIPS POLICIES
-- ================================================
DROP POLICY IF EXISTS "Users can view own friendships" ON friendships;
DROP POLICY IF EXISTS "Users can create own friendships" ON friendships;
DROP POLICY IF EXISTS "Users can delete own friendships" ON friendships;

CREATE POLICY "Users can view own friendships" ON friendships FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);
CREATE POLICY "Users can create own friendships" ON friendships FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own friendships" ON friendships FOR DELETE USING (auth.uid() = user_id);

-- ================================================
-- 11. FUNCTION: AUTO CREATE PROFILE ON SIGNUP
-- ================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    NEW.email,
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 12. TRIGGER: CREATE PROFILE ON USER SIGNUP
-- ================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ================================================
-- 13. FUNCTION: UPDATE TIMESTAMP
-- ================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- 14. TRIGGER: AUTO UPDATE TIMESTAMP
-- ================================================
DROP TRIGGER IF EXISTS set_updated_at ON profiles;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ================================================
-- SETUP COMPLETE! ✅
-- ================================================
-- Next steps:
-- 1. Go to Storage in Supabase
-- 2. Create bucket: profile-pictures (make it PUBLIC)
-- 3. Add upload policy for authenticated users
-- ================================================
