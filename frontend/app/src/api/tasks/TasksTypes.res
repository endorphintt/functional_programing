type taskListItem = {
  id: string,
  topic_id: string,
  title: string,
  created_at: string,
}

type task = {
  id: string,
  topic_id: string,
  title: string,
  statement: string,
  starter_code: string,
  runner: string,
  runner_body: string,
}

type submitResponse = {
  submission_id: string,
  status: string,
  score: int,
  delta: int,
  rating: int,
}

type mySubmissionItem = {
  id: string,
  status: string,
  score: int,
  passed_tests: int,
  total_tests: int,
  created_at: string,
}

type mySubmissions = {
  limit: int,
  offset: int,
  items: array<mySubmissionItem>,
}

type myTaskItem = {
  id: string,
  topic_id: string,
  title: string,
  created_at: string,
  best_score: int,
}

type myBestResponse = {
  best_score: int,
}
