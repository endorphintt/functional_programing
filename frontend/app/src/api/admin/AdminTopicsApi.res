open AdminTopicsTypes

let optsNone: JSON.t = JSON.Encode.object(Dict.make())

let obj = (xs: array<(string, JSON.t)>): JSON.t => {
  let d = Dict.make()
  xs->Array.forEach(((k, v)) => Dict.set(d, k, v))
  JSON.Encode.object(d)
}

let authOpts = (): JSON.t =>
  switch Token.getToken() {
  | None => optsNone
  | Some(t) =>
    obj([("authToken", JSON.Encode.string(t))])
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
  switch Dict.get(o, k) {
  | None => JsError.throwWithMessage("missing " ++ k)
  | Some(v) =>
    switch (JSON.Decode.float(v), JSON.Decode.string(v)) {
    | (Some(f), _) => f->Float.toInt
    | (_, Some(s)) => switch Int.fromString(s) { | Some(i) => i | None => JsError.throwWithMessage("bad int " ++ k) }
    | _ => JsError.throwWithMessage("bad int " ++ k)
    }
  }

let dOptStr = (o: Dict.t<JSON.t>, k: string): option<string> =>
  switch Dict.get(o, k) {
  | None => None
  | Some(v) => v->JSON.Decode.string
  }

let decodeItem = (j: JSON.t): topicAdminListItem => {
  let o = dObj(j)
  {
    id: dStr(o, "id"),
    title: dStr(o, "title"),
    subtitle: dStr(o, "subtitle"),
    created_at: dStr(o, "created_at"),
    archived_at: dOptStr(o, "archived_at"),
  }
}

let decodePageTopic = (j: JSON.t): pageTopicAdmin => {
  let o = dObj(j)
  {
    id: dStr(o, "id"),
    title: dStr(o, "title"),
    subtitle: dStr(o, "subtitle"),
    archived_at: dOptStr(o, "archived_at"),
  }
}

let decodeParagraph = (j: JSON.t): paragraph => {
  let o = dObj(j)
  {
    id: dStr(o, "id"),
    sort_key: dInt(o, "sort_key"),
    body: dStr(o, "body"),
    code: dOptStr(o, "code"),
  }
}

let decodePageTask = (j: JSON.t): pageTask => {
  let o = dObj(j)
  {id: dStr(o, "id"), title: dStr(o, "title"), created_at: dStr(o, "created_at")}
}

let decodeTopicPageAdmin = (j: JSON.t): topicPageAdmin => {
  let o = dObj(j)
  let topic = Dict.get(o, "topic")->Belt.Option.getExn->decodePageTopic
  let paragraphs = Dict.get(o, "paragraphs")->Belt.Option.getExn->dArr->Array.map(decodeParagraph)
  let tasks = Dict.get(o, "tasks")->Belt.Option.getExn->dArr->Array.map(decodePageTask)
  {topic, paragraphs, tasks}
}

let listAdmin = () =>
  Http.getJson(AdminConstants.base ++ "/topics", authOpts())
  ->Promise.then(j => dArr(j)->Array.map(decodeItem)->Promise.resolve)

let pageAdmin = (~id: string) =>
  Http.getJson(AdminConstants.base ++ "/topics/" ++ id ++ "/page", authOpts())
  ->Promise.then(j => decodeTopicPageAdmin(j)->Promise.resolve)

let create = (dto: createTopicRequest) => {
  let body =
    obj([
      ("title", JSON.Encode.string(dto.title)),
      ("subtitle", JSON.Encode.string(dto.subtitle)),
    ])

  Http.postJson(AdminConstants.base ++ "/topics", body, authOpts())
  ->Promise.then(j => {
    let o = dObj(j)
    {id: dStr(o, "id")}->Promise.resolve
  })
}

let archive = (~id: string) =>
  Http.putJson(AdminConstants.base ++ "/topics/" ++ id ++ "/archive", obj([]), authOpts())
  ->Promise.then(_ => Promise.resolve(true))

let unarchive = (~id: string) =>
  Http.putJson(AdminConstants.base ++ "/topics/" ++ id ++ "/unarchive", obj([]), authOpts())
  ->Promise.then(_ => Promise.resolve(true))

let addParagraphs = (~id: string, ~items: array<paragraphIn>) => {
  let body =
    items
    ->Array.map(p =>
      obj([
        ("sort_key", JSON.Encode.int(p.sort_key)),
        ("body", JSON.Encode.string(p.body)),
        ("code", switch p.code { | None => JSON.Encode.null | Some(s) => JSON.Encode.string(s) }),
      ])
    )
    ->JSON.Encode.array

  Http.postJson(AdminConstants.base ++ "/topics/" ++ id ++ "/paragraphs", body, authOpts())
  ->Promise.then(_ => Promise.resolve(true))
}

let deleteParagraph = (~id: string) =>
  Http.deleteJson(AdminConstants.base ++ "/topic-paragraphs/" ++ id, authOpts())
  ->Promise.then(_ => Promise.resolve(true))
