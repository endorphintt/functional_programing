type topic = {
  id: string,
  title: string,
  subtitle: string,
  created_at: string,
}

type pageTopic = {
  id: string,
  title: string,
  subtitle: string,
}

type pageTask = {
  id: string,
  title: string,
  created_at: string,
}

type paragraph = {
  id: string,
  sort_key: int,
  body: string,
  code: option<string>,
}

type topicPage = {
  topic: pageTopic,
  paragraphs: array<paragraph>,
  tasks: array<pageTask>,
}
