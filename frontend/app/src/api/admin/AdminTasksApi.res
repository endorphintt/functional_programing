open AdminTasksTypes

let optsNone: JSON.t = JSON.Encode.object(Dict.make())

let obj = (xs: array<(string, JSON.t)>): JSON.t => {
  let d = Dict.make()
  xs->Array.forEach(((k, v)) => Dict.set(d, k, v))
  JSON.Encode.object(d)
}

let authOpts = (): JSON.t =>
  switch Token.getToken() {
  | None => optsNone
  | Some(t) => obj([("authToken", JSON.Encode.string(t))])
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

let dOptStr = (o: Dict.t<JSON.t>, k: string): option<string> =>
  switch Dict.get(o, k) {
  | None => None
  | Some(v) => v->JSON.Decode.string
  }

let decodeTask = (j: JSON.t): adminTask => {
  let o = dObj(j)
  {
    id: dStr(o, "id"),
    topic_id: dStr(o, "topic_id"),
    title: dStr(o, "title"),
    statement: dStr(o, "statement"),
    starter_code: dStr(o, "starter_code"),
    runner: dStr(o, "runner"),
    runner_body: dStr(o, "runner_body"),
    created_at: dStr(o, "created_at"),
    archived_at: dOptStr(o, "archived_at"),
  }
}

let decodeCreate = (j: JSON.t): createTaskResponse => {
  let o = dObj(j)
  {id: dStr(o, "id")}
}

let list = () =>
  Http.getJson(AdminConstants.base ++ "/tasks", authOpts())
  ->Promise.then(j => dArr(j)->Array.map(decodeTask)->Promise.resolve)

let getOne = (~id: string) =>
  Http.getJson(AdminConstants.base ++ "/tasks/" ++ id, authOpts())
  ->Promise.then(j => decodeTask(j)->Promise.resolve)

let create = (dto: createTaskRequest) => {
  let d: Dict.t<JSON.t> = Dict.make()
  Dict.set(d, "topic_id", JSON.Encode.string(dto.topic_id))
  Dict.set(d, "title", JSON.Encode.string(dto.title))
  Dict.set(d, "statement", JSON.Encode.string(dto.statement))
  Dict.set(d, "starter_code", JSON.Encode.string(dto.starter_code))
  switch dto.runner {
  | None => ()
  | Some(r) => Dict.set(d, "runner", JSON.Encode.string(r))
  }
  switch dto.runner_body {
  | None => ()
  | Some(rb) => Dict.set(d, "runner_body", JSON.Encode.string(rb))
  }
  let body = JSON.Encode.object(d)

  Http.postJson(AdminConstants.base ++ "/tasks", body, authOpts())
  ->Promise.then(j => decodeCreate(j)->Promise.resolve)
}

let archive = (~id: string) =>
  Http.putJson(AdminConstants.base ++ "/tasks/" ++ id ++ "/archive", obj([]), authOpts())
  ->Promise.then(_ => Promise.resolve(true))

let unarchive = (~id: string) =>
  Http.putJson(AdminConstants.base ++ "/tasks/" ++ id ++ "/unarchive", obj([]), authOpts())
  ->Promise.then(_ => Promise.resolve(true))
