ALTER TABLE topics
  ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS topics_archived_at_idx ON topics(archived_at);

CREATE TABLE IF NOT EXISTS topic_paragraphs (
  id BIGSERIAL PRIMARY KEY,
  topic_id BIGINT NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
  sort_key INT NOT NULL,
  body TEXT NOT NULL,
  code TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (topic_id, sort_key)
);

CREATE INDEX IF NOT EXISTS topic_paragraphs_topic_id_idx ON topic_paragraphs(topic_id);
