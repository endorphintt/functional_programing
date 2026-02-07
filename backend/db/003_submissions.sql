CREATE TABLE IF NOT EXISTS user_task_answers (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  status TEXT NOT NULL,
  score INT NOT NULL DEFAULT 0,
  passed_tests INT NOT NULL DEFAULT 0,
  total_tests INT NOT NULL DEFAULT 0,
  result_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS uta_user_task_idx ON user_task_answers(user_id, task_id, created_at DESC);

CREATE TABLE IF NOT EXISTS user_task_best (
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  task_id BIGINT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  best_score INT NOT NULL,
  best_submission_id BIGINT NOT NULL REFERENCES user_task_answers(id) ON DELETE CASCADE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, task_id)
);
