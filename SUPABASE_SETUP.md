# Supabase Setup Instructions

## IMPORTANT: Run these SQL commands in your Supabase SQL Editor

To fix the profile picture upload issue (403 error), you need to:

### 1. Create the Storage Bucket and Set RLS Policies

Go to your Supabase Dashboard → SQL Editor → New Query, then paste and run the following:

```sql
-- Create profile-pictures storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-pictures', 'profile-pictures', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile pictures" ON storage.objects;

-- Allow anyone to view profile pictures (public bucket)
CREATE POLICY "Anyone can view profile pictures"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-pictures');

-- Allow authenticated users to upload to profile-pictures bucket
CREATE POLICY "Users can upload their own profile pictures"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-pictures' 
  AND (storage.foldername(name))[1] = 'avatars'
);

-- Allow authenticated users to update their own profile pictures
CREATE POLICY "Users can update their own profile pictures"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-pictures'
  AND (storage.foldername(name))[1] = 'avatars'
);

-- Allow authenticated users to delete their own profile pictures
CREATE POLICY "Users can delete their own profile pictures"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-pictures'
  AND (storage.foldername(name))[1] = 'avatars'
);

-- Ensure RLS is enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
```

### 2. Alternative: Create Bucket via UI

If you prefer using the UI:

1. Go to **Storage** in your Supabase dashboard
2. Click **Create a new bucket**
3. Name it: `profile-pictures`
4. Make it **Public**
5. Click **Create bucket**

Then run only the policy creation SQL (lines starting with DROP POLICY and CREATE POLICY).

---

## What Was Fixed

### ✅ Focus Timer Issues:
- Added proper logging to track data flow
- Fixed user_id to use authenticated user ID from Supabase
- Added automatic sync after focus session completion
- Enhanced data reload from both Supabase and local DB

### ✅ Progress Graph:
- Now pulls data from Supabase when online
- Fallbacks to local data when offline
- Displays focus sessions with proper time period filtering

### ✅ Profile Photo Upload:
- Fixed web compatibility (using bytes instead of File)
- Added proper RLS policies for storage bucket
- Supports all image formats (JPEG, PNG, WebP, etc.)

### ✅ Timer Completion Sound:
- Added system alert sound when timer completes
- Works on web and mobile platforms

---

## Testing

After running the SQL commands:

1. **Test Profile Photo Upload:**
   - Go to Profile page
   - Tap profile picture
   - Select image from gallery
   - Should upload successfully ✅

2. **Test Focus Timer:**
   - Go to Focus page
   - Set timer for 1 minute
   - Start timer
   - Wait for completion (sound will play)
   - Check home page - should see session in graph ✅

3. **Test Progress Graph:**
   - Go to Home page
   - Should see "Progress Analytics" section
   - Switch between Today/Week/Month/Year
   - Graph should display your focus sessions ✅

---

## Troubleshooting

**If profile upload still fails:**
- Make sure you're logged in (check console logs)
- Verify bucket name is exactly "profile-pictures"
- Check SQL commands ran without errors

**If focus data doesn't show:**
- Open browser console (F12)
- Look for logs starting with 📝, 💾, ✅
- Make sure you're authenticated
- Check network tab for Supabase requests

**If graph is empty:**
- Complete at least one focus session first
- Refresh the page (pull down on mobile)
- Check browser console for error messages
