-- Run this SQL in Supabase SQL Editor to add last_seen column for presence tracking

-- Add last_seen column to profiles table (if not already exists)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Update existing rows to have a last_seen value
UPDATE profiles 
SET last_seen = COALESCE(last_active_date, NOW())
WHERE last_seen IS NULL;

-- Add current_activity column for showing what user is doing
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS current_activity TEXT;

-- Create index for faster queries on last_seen
CREATE INDEX IF NOT EXISTS idx_profiles_last_seen ON profiles(last_seen DESC);

-- Update the last_seen whenever a user is active
-- This will be called automatically by the app every 30 seconds for active users
