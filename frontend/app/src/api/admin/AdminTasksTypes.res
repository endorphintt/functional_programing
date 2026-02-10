type adminTask = {
  id: string,
  topic_id: string,
  title: string,
  statement: string,
  starter_code: string,
  runner: string,
  runner_body: string,
  created_at: string,
  archived_at: option<string>,
}

type createTaskRequest = {
  topic_id: string,
  title: string,
  statement: string,
  starter_code: string,
  runner: option<string>,
  runner_body: option<string>,
}

type createTaskResponse = {id: string}
