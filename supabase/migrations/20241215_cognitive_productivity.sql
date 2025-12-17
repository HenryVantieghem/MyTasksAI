-- Migration: Cognitive Productivity System
-- Adds AI-powered task enhancement features inspired by Sam Altman's productivity system
-- Created: 2024-12-15

-- ============================================
-- 1. Extend tasks table with AI properties
-- ============================================

ALTER TABLE tasks ADD COLUMN IF NOT EXISTS ai_generated_prompt TEXT;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS ai_thought_process TEXT;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS schedule_suggestion JSONB;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS context_notes TEXT;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS star_rating INTEGER DEFAULT 2;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS actual_minutes INTEGER;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- Add comment for documentation
COMMENT ON COLUMN tasks.star_rating IS 'Sam Altman priority: 1=low(*), 2=medium(**), 3=high(***)';
COMMENT ON COLUMN tasks.context_notes IS 'User-provided context for AI enhancement';
COMMENT ON COLUMN tasks.ai_generated_prompt IS 'AI-generated prompt for task completion';

-- ============================================
-- 2. Sub-tasks table (Claude Code style breakdown)
-- ============================================

CREATE TABLE IF NOT EXISTS sub_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    estimated_minutes INTEGER,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    order_index INTEGER NOT NULL,
    ai_reasoning TEXT,  -- Why AI created this sub-task
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE sub_tasks IS 'Claude Code-style task breakdown for step-by-step completion';

-- ============================================
-- 3. YouTube resources for learning
-- ============================================

CREATE TABLE IF NOT EXISTS task_youtube_resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    video_id TEXT NOT NULL,
    title TEXT NOT NULL,
    channel_name TEXT,
    duration_seconds INTEGER,
    view_count INTEGER,
    thumbnail_url TEXT,
    relevance_score FLOAT,  -- AI-calculated relevance (0.0 - 1.0)
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE task_youtube_resources IS 'AI-curated YouTube learning resources for tasks';

-- ============================================
-- 4. Task reflections (post-completion learning)
-- ============================================

CREATE TABLE IF NOT EXISTS task_reflections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id),
    difficulty_rating INTEGER CHECK (difficulty_rating >= 1 AND difficulty_rating <= 5),
    was_estimate_accurate BOOLEAN,
    learnings TEXT,
    tips_for_next JSONB,  -- Array of tips for future similar tasks
    actual_minutes INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE task_reflections IS 'Post-task reflections for learning and AI improvement';

-- ============================================
-- 5. User productivity patterns (AI personalization)
-- ============================================

CREATE TABLE IF NOT EXISTS user_productivity_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) UNIQUE,
    energy_patterns JSONB,  -- {"morning": 0.8, "afternoon": 0.6, "evening": 0.4}
    ai_accuracy_score FLOAT,  -- Rolling average of AI estimate accuracy
    completed_task_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE user_productivity_patterns IS 'Aggregated user patterns for AI personalization';

-- ============================================
-- 6. Performance indexes
-- ============================================

CREATE INDEX IF NOT EXISTS idx_sub_tasks_task_id ON sub_tasks(task_id);
CREATE INDEX IF NOT EXISTS idx_sub_tasks_status ON sub_tasks(status);
CREATE INDEX IF NOT EXISTS idx_youtube_resources_task_id ON task_youtube_resources(task_id);
CREATE INDEX IF NOT EXISTS idx_reflections_task_id ON task_reflections(task_id);
CREATE INDEX IF NOT EXISTS idx_reflections_user_id ON task_reflections(user_id);
CREATE INDEX IF NOT EXISTS idx_productivity_patterns_user_id ON user_productivity_patterns(user_id);

-- ============================================
-- 7. Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS on new tables
ALTER TABLE sub_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_youtube_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_reflections ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_productivity_patterns ENABLE ROW LEVEL SECURITY;

-- Sub-tasks: Users can manage sub-tasks for their own tasks
CREATE POLICY "Users can view their task sub-tasks" ON sub_tasks
    FOR SELECT USING (
        task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can insert sub-tasks for their tasks" ON sub_tasks
    FOR INSERT WITH CHECK (
        task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can update their task sub-tasks" ON sub_tasks
    FOR UPDATE USING (
        task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can delete their task sub-tasks" ON sub_tasks
    FOR DELETE USING (
        task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid())
    );

-- YouTube resources: Same pattern
CREATE POLICY "Users can view their task youtube resources" ON task_youtube_resources
    FOR SELECT USING (
        task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can manage their task youtube resources" ON task_youtube_resources
    FOR ALL USING (
        task_id IN (SELECT id FROM tasks WHERE user_id = auth.uid())
    );

-- Reflections: Users own their reflections
CREATE POLICY "Users can view their reflections" ON task_reflections
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their reflections" ON task_reflections
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their reflections" ON task_reflections
    FOR UPDATE USING (user_id = auth.uid());

-- Productivity patterns: Users own their patterns
CREATE POLICY "Users can view their productivity patterns" ON user_productivity_patterns
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage their productivity patterns" ON user_productivity_patterns
    FOR ALL USING (user_id = auth.uid());

-- ============================================
-- Done! Apply this migration via Supabase dashboard
-- or run: supabase db push
-- ============================================
