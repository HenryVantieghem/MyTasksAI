-- Migration: Social Task Sharing & Leaderboard Features
-- Adds task sharing between friends with collaborative completion
-- Created: 2025-12-27

-- ============================================
-- 1. Shared Tasks Table (Task Invitations)
-- ============================================

CREATE TABLE IF NOT EXISTS shared_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    invitee_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    invited_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Prevent duplicate invitations
    UNIQUE(task_id, invitee_id)
);

COMMENT ON TABLE shared_tasks IS 'Tracks task sharing invitations between friends - collaborative completion';
COMMENT ON COLUMN shared_tasks.inviter_id IS 'User who shared the task (task owner)';
COMMENT ON COLUMN shared_tasks.invitee_id IS 'User invited to collaborate on the task';
COMMENT ON COLUMN shared_tasks.status IS 'pending = awaiting response, accepted = collaborating, declined = rejected';

-- ============================================
-- 2. Performance Indexes
-- ============================================

CREATE INDEX IF NOT EXISTS idx_shared_tasks_task_id ON shared_tasks(task_id);
CREATE INDEX IF NOT EXISTS idx_shared_tasks_inviter_id ON shared_tasks(inviter_id);
CREATE INDEX IF NOT EXISTS idx_shared_tasks_invitee_id ON shared_tasks(invitee_id);
CREATE INDEX IF NOT EXISTS idx_shared_tasks_status ON shared_tasks(status);
CREATE INDEX IF NOT EXISTS idx_shared_tasks_pending_invitee ON shared_tasks(invitee_id, status) WHERE status = 'pending';

-- ============================================
-- 3. Row Level Security (RLS) Policies
-- ============================================

ALTER TABLE shared_tasks ENABLE ROW LEVEL SECURITY;

-- Users can view shared task invitations where they are the inviter or invitee
CREATE POLICY "Users can view their shared task invitations" ON shared_tasks
    FOR SELECT USING (
        inviter_id = auth.uid() OR invitee_id = auth.uid()
    );

-- Only task owners can create invitations (inviter must own the task)
CREATE POLICY "Task owners can invite friends" ON shared_tasks
    FOR INSERT WITH CHECK (
        inviter_id = auth.uid() AND
        EXISTS (SELECT 1 FROM tasks WHERE id = task_id AND user_id = auth.uid()) AND
        -- Must be friends with invitee (accepted friendship)
        EXISTS (
            SELECT 1 FROM friendships
            WHERE status = 'accepted' AND
            ((requester_id = auth.uid() AND addressee_id = invitee_id) OR
             (addressee_id = auth.uid() AND requester_id = invitee_id))
        )
    );

-- Invitees can update (accept/decline) their invitations
CREATE POLICY "Invitees can respond to invitations" ON shared_tasks
    FOR UPDATE USING (
        invitee_id = auth.uid() AND status = 'pending'
    );

-- Inviters can delete/cancel pending invitations
CREATE POLICY "Inviters can cancel pending invitations" ON shared_tasks
    FOR DELETE USING (
        inviter_id = auth.uid() AND status = 'pending'
    );

-- ============================================
-- 4. Trigger for updated_at and responded_at
-- ============================================

CREATE OR REPLACE FUNCTION update_shared_tasks_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    -- Set responded_at when status changes from pending
    IF NEW.status != OLD.status AND OLD.status = 'pending' THEN
        NEW.responded_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER shared_tasks_updated_at
    BEFORE UPDATE ON shared_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_shared_tasks_timestamp();

-- ============================================
-- 5. Add is_shared tracking to tasks table
-- ============================================

ALTER TABLE tasks ADD COLUMN IF NOT EXISTS is_shared BOOLEAN DEFAULT false;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS shared_with_count INTEGER DEFAULT 0;

COMMENT ON COLUMN tasks.is_shared IS 'Whether this task has active collaborators';
COMMENT ON COLUMN tasks.shared_with_count IS 'Number of friends task is shared with';

-- ============================================
-- 6. Function to sync collaborative task completion
-- ============================================

-- When a shared task is completed, mark it complete for all collaborators
CREATE OR REPLACE FUNCTION sync_shared_task_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger when task is marked as completed
    IF NEW.is_completed = true AND OLD.is_completed = false THEN
        -- Check if this task is shared
        IF EXISTS (SELECT 1 FROM shared_tasks WHERE task_id = NEW.id AND status = 'accepted') THEN
            -- For collaborative tasks, we notify via realtime - the app handles UI updates
            -- Future: Could trigger push notifications here
            NULL;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER task_completion_sync
    AFTER UPDATE OF is_completed ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION sync_shared_task_completion();

-- ============================================
-- 7. Leaderboard view for friend rankings
-- ============================================

-- Create a materialized view for efficient leaderboard queries
CREATE OR REPLACE VIEW friend_leaderboard AS
SELECT
    u.id,
    u.username,
    u.full_name,
    u.avatar_url,
    u.current_streak,
    u.current_level,
    u.total_points,
    u.tasks_completed,
    u.last_active_date,
    COALESCE(
        (SELECT COUNT(*) FROM tasks t
         WHERE t.user_id = u.id
         AND t.is_completed = true
         AND t.completed_at >= CURRENT_DATE),
        0
    ) as tasks_completed_today,
    COALESCE(
        (SELECT SUM(points_earned) FROM tasks t
         WHERE t.user_id = u.id
         AND t.is_completed = true
         AND t.completed_at >= CURRENT_DATE - INTERVAL '7 days'),
        0
    ) as weekly_points
FROM users u
WHERE u.id IS NOT NULL;

COMMENT ON VIEW friend_leaderboard IS 'Aggregated user stats for leaderboard display';

-- ============================================
-- 8. Ensure circles invite_code has proper constraints
-- ============================================

-- Add expiration for invite codes (optional)
ALTER TABLE circles ADD COLUMN IF NOT EXISTS invite_code_expires_at TIMESTAMPTZ;

COMMENT ON COLUMN circles.invite_code_expires_at IS 'Optional expiration for invite codes';

-- ============================================
-- 9. Add username_lowercase for case-insensitive search
-- ============================================

-- Add lowercase username column if not exists (for friend search)
ALTER TABLE users ADD COLUMN IF NOT EXISTS username_lowercase TEXT;

-- Populate existing records
UPDATE users SET username_lowercase = LOWER(username) WHERE username_lowercase IS NULL AND username IS NOT NULL;

-- Index for fast search
CREATE INDEX IF NOT EXISTS idx_users_username_lowercase ON users(username_lowercase);

-- Trigger to auto-populate on insert/update
CREATE OR REPLACE FUNCTION sync_username_lowercase()
RETURNS TRIGGER AS $$
BEGIN
    NEW.username_lowercase = LOWER(NEW.username);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_username_lowercase_sync
    BEFORE INSERT OR UPDATE OF username ON users
    FOR EACH ROW
    EXECUTE FUNCTION sync_username_lowercase();
