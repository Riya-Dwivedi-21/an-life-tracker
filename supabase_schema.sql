-- Supabase Database Schema for AN Life Tracker

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (extends auth.users)
CREATE TABLE profiles (
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

-- Focus Sessions table
CREATE TABLE focus_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  duration_minutes INTEGER NOT NULL,
  subject_tags TEXT[] DEFAULT '{}',
  session_date TIMESTAMP WITH TIME ZONE NOT NULL,
  completed BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Calorie Entries table
CREATE TABLE calorie_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('food', 'burn')),
  description TEXT NOT NULL,
  amount INTEGER NOT NULL,
  entry_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Friendships table
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  friend_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'accepted' CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);

-- Indexes for better query performance
CREATE INDEX idx_focus_sessions_user_date ON focus_sessions(user_id, session_date DESC);
CREATE INDEX idx_calorie_entries_user_date ON calorie_entries(user_id, entry_date DESC);
CREATE INDEX idx_friendships_user ON friendships(user_id);
CREATE INDEX idx_profiles_unique_id ON profiles(unique_id);

-- Row Level Security (RLS) Policies

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE focus_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE calorie_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view all profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Focus sessions policies
CREATE POLICY "Users can view own focus sessions" ON focus_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own focus sessions" ON focus_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own focus sessions" ON focus_sessions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own focus sessions" ON focus_sessions FOR DELETE USING (auth.uid() = user_id);

-- Calorie entries policies
CREATE POLICY "Users can view own calorie entries" ON calorie_entries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own calorie entries" ON calorie_entries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own calorie entries" ON calorie_entries FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own calorie entries" ON calorie_entries FOR DELETE USING (auth.uid() = user_id);

-- Friendships policies
CREATE POLICY "Users can view own friendships" ON friendships FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);
CREATE POLICY "Users can create own friendships" ON friendships FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own friendships" ON friendships FOR DELETE USING (auth.uid() = user_id);

-- Functions

-- Function to automatically create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for profiles updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- View for leaderboard data
CREATE OR REPLACE VIEW leaderboard_view AS
SELECT 
  p.id,
  p.full_name,
  p.avatar_url,
  p.hide_focus,
  p.hide_calories,
  COALESCE(
    CASE WHEN p.hide_focus = FALSE 
    THEN SUM(CASE WHEN fs.session_date >= NOW() - INTERVAL '7 days' THEN fs.duration_minutes ELSE 0 END) / 60
    ELSE 0 END,
    0
  ) as weekly_focus_hours,
  COALESCE(
    CASE WHEN p.hide_calories = FALSE
    THEN SUM(CASE WHEN ce.entry_date >= NOW() - INTERVAL '7 days' AND ce.type = 'burn' THEN ce.amount ELSE 0 END)
    ELSE 0 END,
    0
  ) as weekly_calories_burned
FROM profiles p
LEFT JOIN focus_sessions fs ON p.id = fs.user_id
LEFT JOIN calorie_entries ce ON p.id = ce.user_id
GROUP BY p.id, p.full_name, p.avatar_url, p.hide_focus, p.hide_calories;
