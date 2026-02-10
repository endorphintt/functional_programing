ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS runner_body TEXT NOT NULL DEFAULT 'Solution.solve input';
