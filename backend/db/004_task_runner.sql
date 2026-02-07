DO $$
BEGIN
  CREATE TYPE task_runner AS ENUM ('int1', 'int2', 'json');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS runner task_runner NOT NULL DEFAULT 'json';

UPDATE tasks t
SET runner = CASE
  WHEN EXISTS (
    SELECT 1
    FROM task_tests tt
    WHERE tt.task_id = t.id
      AND jsonb_typeof(tt.input_json) = 'array'
  ) THEN 'int2'::task_runner
  ELSE 'int1'::task_runner
END
WHERE t.runner = 'json'::task_runner;
