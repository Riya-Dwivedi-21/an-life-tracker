-- Run this SQL in Supabase SQL Editor to update the friendship deletion policy
-- This allows either user in a friendship to remove the other

-- First, drop the existing delete policy
DROP POLICY IF EXISTS "Users can delete own friendships" ON friendships;

-- Create new policy that allows either user to delete the friendship
CREATE POLICY "Users can delete friendships" ON friendships 
FOR DELETE USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- You may also want to add the ability to insert friendships for the friend
-- This is needed for bidirectional friendship creation
DROP POLICY IF EXISTS "Users can create own friendships" ON friendships;

CREATE POLICY "Users can create friendships" ON friendships 
FOR INSERT WITH CHECK (auth.uid() = user_id OR auth.uid() = friend_id);
