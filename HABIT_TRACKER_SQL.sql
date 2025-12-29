-- ============================================
-- HABIT TRACKER - Database Schema Setup
-- ============================================
-- Run this SQL in your Supabase SQL Editor

-- 1. Create habits table
CREATE TABLE IF NOT EXISTS habits (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  frequency TEXT DEFAULT 'daily',
  target_count INTEGER DEFAULT 30,
  color TEXT DEFAULT '#ff6b35',
  icon TEXT DEFAULT '✓',
  is_archived BOOLEAN DEFAULT false,
  active_months TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create habit_logs table
CREATE TABLE IF NOT EXISTS habit_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  habit_id UUID REFERENCES habits(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  completed BOOLEAN DEFAULT false,
  count INTEGER DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(habit_id, date)
);

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_habits_user_id ON habits(user_id);
CREATE INDEX IF NOT EXISTS idx_habits_active_months ON habits USING GIN(active_months);
CREATE INDEX IF NOT EXISTS idx_habit_logs_user_id ON habit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_habit_logs_habit_id ON habit_logs(habit_id);
CREATE INDEX IF NOT EXISTS idx_habit_logs_date ON habit_logs(date);

-- 4. Enable Row Level Security
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_logs ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for habits table
-- Users can view their own habits + friends' habits
DROP POLICY IF EXISTS "Users can view own and friends habits" ON habits;
CREATE POLICY "Users can view own and friends habits" ON habits
  FOR SELECT USING (
    auth.uid() = user_id 
    OR 
    EXISTS (
      SELECT 1 FROM friendships 
      WHERE (
        (friendships.user_id = auth.uid() AND friendships.friend_id = habits.user_id)
        OR
        (friendships.friend_id = auth.uid() AND friendships.user_id = habits.user_id)
      )
      AND friendships.status = 'accepted'
    )
  );

-- Users can insert their own habits
DROP POLICY IF EXISTS "Users can insert own habits" ON habits;
CREATE POLICY "Users can insert own habits" ON habits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own habits
DROP POLICY IF EXISTS "Users can update own habits" ON habits;
CREATE POLICY "Users can update own habits" ON habits
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own habits
DROP POLICY IF EXISTS "Users can delete own habits" ON habits;
CREATE POLICY "Users can delete own habits" ON habits
  FOR DELETE USING (auth.uid() = user_id);

-- 6. RLS Policies for habit_logs table
-- Users can view their own logs + friends' logs
DROP POLICY IF EXISTS "Users can view own and friends habit logs" ON habit_logs;
CREATE POLICY "Users can view own and friends habit logs" ON habit_logs
  FOR SELECT USING (
    auth.uid() = user_id 
    OR 
    EXISTS (
      SELECT 1 FROM friendships 
      WHERE (
        (friendships.user_id = auth.uid() AND friendships.friend_id = habit_logs.user_id)
        OR
        (friendships.friend_id = auth.uid() AND friendships.user_id = habit_logs.user_id)
      )
      AND friendships.status = 'accepted'
    )
  );

-- Users can insert their own logs
DROP POLICY IF EXISTS "Users can insert own habit logs" ON habit_logs;
CREATE POLICY "Users can insert own habit logs" ON habit_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own logs
DROP POLICY IF EXISTS "Users can update own habit logs" ON habit_logs;
CREATE POLICY "Users can update own habit logs" ON habit_logs
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own logs
DROP POLICY IF EXISTS "Users can delete own habit logs" ON habit_logs;
CREATE POLICY "Users can delete own habit logs" ON habit_logs
  FOR DELETE USING (auth.uid() = user_id);

-- 7. Optional: Create a function to get habit stats
CREATE OR REPLACE FUNCTION get_habit_stats(p_user_id UUID, p_month_key TEXT)
RETURNS TABLE (
  total_habits BIGINT,
  completed_today BIGINT,
  monthly_completion_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH active_habits AS (
    SELECT id FROM habits
    WHERE user_id = p_user_id
      AND (active_months IS NULL OR p_month_key = ANY(active_months))
      AND NOT is_archived
  ),
  today_logs AS (
    SELECT COUNT(*) as completed
    FROM habit_logs hl
    JOIN active_habits ah ON hl.habit_id = ah.id
    WHERE hl.date = CURRENT_DATE
      AND hl.completed = true
  )
  SELECT
    (SELECT COUNT(*) FROM active_habits),
    (SELECT completed FROM today_logs),
    COALESCE(
      (SELECT
        (COUNT(*) FILTER (WHERE completed = true)::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0)) * 100
       FROM habit_logs hl
       JOIN active_habits ah ON hl.habit_id = ah.id
       WHERE DATE_TRUNC('month', hl.date) = DATE_TRUNC('month', CURRENT_DATE)
      ), 0
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Optional: Enable Realtime for notifications
-- ============================================
-- ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
-- Note: Notifications table already added to realtime

-- ============================================
-- DONE! Your habit tracker database is ready.
-- ============================================
