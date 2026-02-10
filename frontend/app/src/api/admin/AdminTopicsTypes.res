type topicAdminListItem = {
  id: string,
  title: string,
  subtitle: string,
  created_at: string,
  archived_at: option<string>,
}

type createTopicRequest = {
  title: string,
  subtitle: string,
}

type createTopicResponse = {id: string}

type pageTopicAdmin = {
  id: string,
  title: string,
  subtitle: string,
  archived_at: option<string>,
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

type topicPageAdmin = {
  topic: pageTopicAdmin,
  paragraphs: array<paragraph>,
  tasks: array<pageTask>,
}

type paragraphIn = {
  sort_key: int,
  body: string,
  code: option<string>,
}
