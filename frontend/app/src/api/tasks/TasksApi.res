open TasksTypes

let optsNone: JSON.t = JSON.Encode.object(Dict.make())

let obj = (xs: array<(string, JSON.t)>): JSON.t => {
  let d = Dict.make()
  xs->Array.forEach(((k, v)) => Dict.set(d, k, v))
  JSON.Encode.object(d)
}

let dObj = (j: JSON.t): Dict.t<JSON.t> =>
  switch JSON.Decode.object(j) {
  | Some(o) => o
  | None => JsError.throwWithMessage("bad json")
  }

let dArr = (j: JSON.t): array<JSON.t> =>
  switch JSON.Decode.array(j) {
  | Some(xs) => xs
  | None => JsError.throwWithMessage("bad json")
  }

let dStr = (o: Dict.t<JSON.t>, k: string): string =>
  switch Dict.get(o, k)->Belt.Option.flatMap(JSON.Decode.string) {
  | Some(v) => v
  | None => JsError.throwWithMessage("missing " ++ k)
  }

let dInt = (o: Dict.t<JSON.t>, k: string): int =>
  switch Dict.get(o, k)->Belt.Option.flatMap(JSON.Decode.float) {
  | Some(v) => v->Float.toInt
  | None => JsError.throwWithMessage("missing " ++ k)
  }

let dArrField = (o: Dict.t<JSON.t>, k: string): array<JSON.t> =>
  switch Dict.get(o, k)->Belt.Option.flatMap(JSON.Decode.array) {
  | Some(v) => v
  | None => JsError.throwWithMessage("missing " ++ k)
  }

let authOpts = (): JSON.t =>
  switch Token.getToken() {
  | None => optsNone
  | Some(t) => obj([("authToken", JSON.Encode.string(t))])
  }

let decodeTaskListItem = (j: JSON.t): taskListItem => {
  let o = dObj(j)
  {
    id: dStr(o, "id"),
    topic_id: dStr(o, "topic_id"),
    title: dStr(o, "title"),
    created_at: dStr(o, "created_at"),
  }
}

let decodeTask = (j: JSON.t): task => {
  let o = dObj(j)
  {
    id: dStr(o, "id"),
    topic_id: dStr(o, "topic_id"),
    title: dStr(o, "title"),
    statement: dStr(o, "statement"),
    starter_code: dStr(o, "starter_code"),
    runner: dStr(o, "runner"),
    runner_body: dStr(o, "runner_body"),
  }
}

let decodeSubmit = (j: JSON.t): submitResponse => {
  let o = dObj(j)
  {
    submission_id: dStr(o, "submission_id"),
    status: dStr(o, "status"),
    score: dInt(o, "score"),
    delta: dInt(o, "delta"),
    rating: dInt(o, "rating"),
  }
}

let decodeMySubmissionItem = (j: JSON.t): mySubmissionItem => {
  let o = dObj(j)
  {
    id: dStr(o, "id"),
    status: dStr(o, "status"),
    score: dInt(o, "score"),
    passed_tests: dInt(o, "passed_tests"),
    total_tests: dInt(o, "total_tests"),
    created_at: dStr(o, "created_at"),
  }
}

let decodeMySubmissions = (j: JSON.t): mySubmissions => {
  let o = dObj(j)
  let items = dArrField(o, "items")->Array.map(decodeMySubmissionItem)
  {limit: dInt(o, "limit"), offset: dInt(o, "offset"), items}
}

let decodeMyTaskItem = (j: JSON.t): myTaskItem => {
  let o = dObj(j)
  {
    id: dStr(o, "id"),
    topic_id: dStr(o, "topic_id"),
    title: dStr(o, "title"),
    created_at: dStr(o, "created_at"),
    best_score: dInt(o, "best_score"),
  }
}

let decodeMyBest = (j: JSON.t): myBestResponse => {
  let o = dObj(j)
  {best_score: dInt(o, "best_score")}
}

let listAll = () =>
  Http.getJson("/tasks", optsNone)
  ->Promise.then(j => dArr(j)->Array.map(decodeTaskListItem)->Promise.resolve)

let listByTopic = (~topicId: string) =>
  Http.getJson("/topics/" ++ topicId ++ "/tasks", optsNone)
  ->Promise.then(j => dArr(j)->Array.map(decodeTaskListItem)->Promise.resolve)

let getOne = (~id: string) =>
  Http.getJson("/tasks/" ++ id, optsNone)
  ->Promise.then(j => decodeTask(j)->Promise.resolve)

let submit = (~id: string, ~code: string) => {
  let body = obj([("code", JSON.Encode.string(code))])
  Http.postJson("/tasks/" ++ id ++ "/submit", body, authOpts())
  ->Promise.then(j => decodeSubmit(j)->Promise.resolve)
}

let mySubmissions = (~id: string, ~limit: option<int>=?, ~offset: option<int>=?) => {
  let q =
    switch (limit, offset) {
    | (None, None) => ""
    | _ =>
      let l = switch limit { | Some(v) => "limit=" ++ v->Int.toString | None => "" }
      let o = switch offset { | Some(v) => "offset=" ++ v->Int.toString | None => "" }
      let sep = if l != "" && o != "" { "&" } else { "" }
      "?" ++ l ++ sep ++ o
    }

  Http.getJson("/tasks/" ++ id ++ "/submissions" ++ q, authOpts())
  ->Promise.then(j => decodeMySubmissions(j)->Promise.resolve)
}

let myTasks = () =>
  Http.getJson("/tasks/my", authOpts())
  ->Promise.then(j =>
    switch JSON.Decode.array(j) {
    | Some(xs) => xs->Array.map(decodeMyTaskItem)->Promise.resolve
    | None => JsError.throwWithMessage("bad json")
    }
  )

let myBest = (~id: string) =>
  Http.getJson("/tasks/" ++ id ++ "/my-best", authOpts())
  ->Promise.then(j => decodeMyBest(j)->Promise.resolve)
