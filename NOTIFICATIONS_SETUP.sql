-- Run this SQL in Supabase SQL Editor to create notifications table

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE,
  CONSTRAINT different_users CHECK (sender_id != receiver_id)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_receiver ON notifications(receiver_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(receiver_id, read_at) WHERE read_at IS NULL;

-- Enable Row Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view notifications they sent or received
CREATE POLICY "Users can view their notifications" ON notifications
  FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Users can send notifications to their friends
CREATE POLICY "Users can send notifications to friends" ON notifications
  FOR INSERT
  WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM friendships
      WHERE user_id = auth.uid()
      AND friend_id = receiver_id
      AND status = 'accepted'
    )
  );

-- Users can mark their own received notifications as read
CREATE POLICY "Users can mark notifications as read" ON notifications
  FOR UPDATE
  USING (auth.uid() = receiver_id)
  WITH CHECK (auth.uid() = receiver_id);

-- Users can delete notifications they received
CREATE POLICY "Users can delete their notifications" ON notifications
  FOR DELETE
  USING (auth.uid() = receiver_id);
