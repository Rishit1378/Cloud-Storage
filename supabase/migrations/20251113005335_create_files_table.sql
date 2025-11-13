/*
  # Create Files Management System

  1. New Tables
    - `files`
      - `id` (uuid, primary key) - Unique identifier for each file record
      - `user_id` (uuid, foreign key) - References auth.users, tracks file ownership
      - `filename` (text) - Original name of the uploaded file
      - `file_path` (text) - Storage path in Supabase Storage
      - `file_size` (bigint) - Size of the file in bytes
      - `mime_type` (text) - MIME type of the file
      - `created_at` (timestamptz) - Timestamp when file was uploaded
      
  2. Security
    - Enable RLS on `files` table
    - Add policy for users to view only their own files
    - Add policy for users to insert their own files
    - Add policy for users to delete their own files
    
  3. Storage
    - Create a storage bucket for user files
    - Enable RLS on the storage bucket
    - Add policies for users to upload, view, and delete only their own files
*/

CREATE TABLE IF NOT EXISTS files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  filename text NOT NULL,
  file_path text NOT NULL,
  file_size bigint NOT NULL DEFAULT 0,
  mime_type text NOT NULL DEFAULT 'application/octet-stream',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE files ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own files"
  ON files FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own files"
  ON files FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own files"
  ON files FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

INSERT INTO storage.buckets (id, name, public)
VALUES ('user-files', 'user-files', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Users can upload own files"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'user-files' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can view own files"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'user-files' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete own files"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'user-files' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );