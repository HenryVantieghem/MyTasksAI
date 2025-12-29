-- Migration: Pacts - Mutual Accountability Streaks
-- If one person fails, both lose the streak
-- Created: 2025-12-28

-- ============================================
-- 1. Pacts Table (Mutual Accountability)
-- ============================================

CREATE TABLE IF NOT EXISTS pacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    initiator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    partner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- The Commitment
    commitment_type TEXT NOT NULL DEFAULT 'daily_tasks'
        CHECK (commitment_type IN ('daily_tasks', 'focus_time', 'goal_progress', 'custom')),
    target_value INT NOT NULL DEFAULT 1,
    custom_description TEXT,

    -- Status
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'active', 'completed', 'broken')),
    accepted_at TIMESTAMPTZ,
    broken_at TIMESTAMPTZ,
    broken_by_user_id UUID REFERENCES auth.users(id),

    -- The Mutual Streak
    current_streak INT NOT NULL DEFAULT 0,
    longest_streak INT NOT NULL DEFAULT 0,
    initiator_completed_today BOOLEAN NOT NULL DEFAULT FALSE,
    partner_completed_today BOOLEAN NOT NULL DEFAULT FALSE,
    last_checked_date DATE,

    -- Protection (Pact Shield power-up)
    shield_active BOOLEAN NOT NULL DEFAULT FALSE,
    shield_used_at TIMESTAMPTZ,

    -- Gamification
    xp_earned INT NOT NULL DEFAULT 0,
    milestones_reached INT[] DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT different_users CHECK (initiator_id != partner_id)
);

COMMENT ON TABLE pacts IS 'Mutual accountability pacts - if one fails, both lose the streak';
COMMENT ON COLUMN pacts.initiator_id IS 'User who proposed the pact';
COMMENT ON COLUMN pacts.partner_id IS 'User who accepted the pact';
COMMENT ON COLUMN pacts.commitment_type IS 'Type: daily_tasks, focus_time, goal_progress, custom';
COMMENT ON COLUMN pacts.target_value IS 'e.g., 3 tasks/day, 30 minutes focus, etc.';
COMMENT ON COLUMN pacts.status IS 'pending=awaiting accept, active=running, completed=mutual end, broken=failed';
COMMENT ON COLUMN pacts.broken_by_user_id IS 'Which user broke the pact (failed their commitment)';
COMMENT ON COLUMN pacts.current_streak IS 'Days both users have succeeded consecutively';
COMMENT ON COLUMN pacts.longest_streak IS 'Best streak ever achieved in this pact';
COMMENT ON COLUMN pacts.initiator_completed_today IS 'Has initiator met today commitment?';
COMMENT ON COLUMN pacts.partner_completed_today IS 'Has partner met today commitment?';
COMMENT ON COLUMN pacts.shield_active IS 'Pact Shield protects both users for one day';
COMMENT ON COLUMN pacts.milestones_reached IS 'Array of milestone days reached (7, 30, 100)';

-- ============================================
-- 2. Performance Indexes
-- ============================================

CREATE INDEX IF NOT EXISTS idx_pacts_initiator_id ON pacts(initiator_id);
CREATE INDEX IF NOT EXISTS idx_pacts_partner_id ON pacts(partner_id);
CREATE INDEX IF NOT EXISTS idx_pacts_status ON pacts(status);
CREATE INDEX IF NOT EXISTS idx_pacts_active_initiator ON pacts(initiator_id, status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_pacts_active_partner ON pacts(partner_id, status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_pacts_pending ON pacts(partner_id, status) WHERE status = 'pending';

-- ============================================
-- 3. Row Level Security (RLS) Policies
-- ============================================

ALTER TABLE pacts ENABLE ROW LEVEL SECURITY;

-- Users can view pacts where they are initiator or partner
CREATE POLICY "Users can view their pacts" ON pacts
    FOR SELECT USING (
        initiator_id = auth.uid() OR partner_id = auth.uid()
    );

-- Users can create pacts (only as initiator, must be friends with partner)
CREATE POLICY "Users can create pacts with friends" ON pacts
    FOR INSERT WITH CHECK (
        initiator_id = auth.uid() AND
        -- Must be friends with partner (accepted friendship)
        EXISTS (
            SELECT 1 FROM friendships
            WHERE status = 'accepted' AND
            ((requester_id = auth.uid() AND addressee_id = partner_id) OR
             (addressee_id = auth.uid() AND requester_id = partner_id))
        )
    );

-- Pact members can update (accept, record progress, end, etc.)
CREATE POLICY "Pact members can update" ON pacts
    FOR UPDATE USING (
        initiator_id = auth.uid() OR partner_id = auth.uid()
    );

-- Initiators can delete pending pacts (cancel invitation)
CREATE POLICY "Initiators can cancel pending pacts" ON pacts
    FOR DELETE USING (
        initiator_id = auth.uid() AND status = 'pending'
    );

-- ============================================
-- 4. Trigger for updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_pacts_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER pacts_updated_at
    BEFORE UPDATE ON pacts
    FOR EACH ROW
    EXECUTE FUNCTION update_pacts_timestamp();

-- ============================================
-- 5. Function to record daily progress
-- ============================================

CREATE OR REPLACE FUNCTION record_pact_progress(
    p_pact_id UUID,
    p_user_id UUID,
    p_completed BOOLEAN
)
RETURNS BOOLEAN AS $$
DECLARE
    v_pact pacts;
    v_is_initiator BOOLEAN;
BEGIN
    -- Get the pact
    SELECT * INTO v_pact FROM pacts WHERE id = p_pact_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pact not found';
    END IF;

    IF v_pact.status != 'active' THEN
        RAISE EXCEPTION 'Pact is not active';
    END IF;

    -- Determine if user is initiator or partner
    v_is_initiator := (v_pact.initiator_id = p_user_id);

    IF NOT v_is_initiator AND v_pact.partner_id != p_user_id THEN
        RAISE EXCEPTION 'User is not a member of this pact';
    END IF;

    -- Update the appropriate completion flag
    IF v_is_initiator THEN
        UPDATE pacts SET initiator_completed_today = p_completed WHERE id = p_pact_id;
    ELSE
        UPDATE pacts SET partner_completed_today = p_completed WHERE id = p_pact_id;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 6. Function for daily pact reset (cron job)
-- ============================================

CREATE OR REPLACE FUNCTION check_pact_daily_reset()
RETURNS void AS $$
DECLARE
    v_pact RECORD;
    v_new_streak INT;
    v_milestones INT[];
BEGIN
    -- Process all active pacts that haven't been checked today
    FOR v_pact IN
        SELECT * FROM pacts
        WHERE status = 'active'
        AND (last_checked_date IS NULL OR last_checked_date < CURRENT_DATE)
    LOOP
        -- Case 1: Both completed - increment streak!
        IF v_pact.initiator_completed_today AND v_pact.partner_completed_today THEN
            v_new_streak := v_pact.current_streak + 1;
            v_milestones := v_pact.milestones_reached;

            -- Check for new milestones
            IF v_new_streak = 7 AND NOT (7 = ANY(v_milestones)) THEN
                v_milestones := array_append(v_milestones, 7);
            END IF;
            IF v_new_streak = 30 AND NOT (30 = ANY(v_milestones)) THEN
                v_milestones := array_append(v_milestones, 30);
            END IF;
            IF v_new_streak = 100 AND NOT (100 = ANY(v_milestones)) THEN
                v_milestones := array_append(v_milestones, 100);
            END IF;

            UPDATE pacts SET
                current_streak = v_new_streak,
                longest_streak = GREATEST(longest_streak, v_new_streak),
                initiator_completed_today = FALSE,
                partner_completed_today = FALSE,
                last_checked_date = CURRENT_DATE,
                milestones_reached = v_milestones,
                xp_earned = xp_earned + (50 * v_new_streak)  -- Bonus XP scales with streak
            WHERE id = v_pact.id;

        -- Case 2: Shield is active - protect the streak
        ELSIF v_pact.shield_active THEN
            UPDATE pacts SET
                shield_active = FALSE,
                shield_used_at = NOW(),
                initiator_completed_today = FALSE,
                partner_completed_today = FALSE,
                last_checked_date = CURRENT_DATE
            WHERE id = v_pact.id;

        -- Case 3: Someone failed - break the pact
        ELSE
            UPDATE pacts SET
                status = 'broken',
                broken_at = NOW(),
                broken_by_user_id = CASE
                    WHEN NOT v_pact.initiator_completed_today THEN v_pact.initiator_id
                    ELSE v_pact.partner_id
                END,
                current_streak = 0,
                last_checked_date = CURRENT_DATE
            WHERE id = v_pact.id;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. Grant execute permission on functions
-- ============================================

GRANT EXECUTE ON FUNCTION record_pact_progress(UUID, UUID, BOOLEAN) TO authenticated;

-- ============================================
-- 8. Realtime subscription setup
-- ============================================

-- Enable realtime for pacts table
ALTER PUBLICATION supabase_realtime ADD TABLE pacts;

-- ============================================
-- 9. Pact activity logging (optional)
-- ============================================

CREATE TABLE IF NOT EXISTS pact_activity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pact_id UUID NOT NULL REFERENCES pacts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL
        CHECK (activity_type IN ('created', 'accepted', 'declined', 'progress', 'milestone', 'broken', 'completed', 'shield_used')),
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE pact_activity IS 'Activity log for pact events';

CREATE INDEX IF NOT EXISTS idx_pact_activity_pact_id ON pact_activity(pact_id);
CREATE INDEX IF NOT EXISTS idx_pact_activity_user_id ON pact_activity(user_id);
CREATE INDEX IF NOT EXISTS idx_pact_activity_type ON pact_activity(activity_type);

ALTER TABLE pact_activity ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view activity for their pacts" ON pact_activity
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM pacts
            WHERE pacts.id = pact_activity.pact_id
            AND (pacts.initiator_id = auth.uid() OR pacts.partner_id = auth.uid())
        )
    );

CREATE POLICY "System can insert pact activity" ON pact_activity
    FOR INSERT WITH CHECK (user_id = auth.uid());
