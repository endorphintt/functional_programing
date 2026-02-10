INSERT INTO topics (title, subtitle)
SELECT 'General', ''
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE title = 'General');

ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS topic_id BIGINT;

UPDATE tasks
SET topic_id = (SELECT id FROM topics WHERE title = 'General')
WHERE topic_id IS NULL;

ALTER TABLE tasks
  ALTER COLUMN topic_id SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'tasks_topic_id_fk'
  ) THEN
    ALTER TABLE tasks
      ADD CONSTRAINT tasks_topic_id_fk
      FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE RESTRICT;
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS tasks_topic_id_idx ON tasks(topic_id);
