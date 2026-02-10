open TopicsTypes

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

let decodeTopic = (j: JSON.t): topic => {
  let o = dObj(j)
  {
    id: dStr(o, "id"),
    title: dStr(o, "title"),
    subtitle: dStr(o, "subtitle"),
    created_at: dStr(o, "created_at"),
  }
}

let decodePageTopic = (j: JSON.t): pageTopic => {
  let o = dObj(j)
  {id: dStr(o, "id"), title: dStr(o, "title"), subtitle: dStr(o, "subtitle")}
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

let decodeTopicPage = (j: JSON.t): topicPage => {
  let o = dObj(j)
  let topic = Dict.get(o, "topic")->Belt.Option.getExn->decodePageTopic
  let paragraphs = Dict.get(o, "paragraphs")->Belt.Option.getExn->dArr->Array.map(decodeParagraph)
  let tasks = Dict.get(o, "tasks")->Belt.Option.getExn->dArr->Array.map(decodePageTask)
  {topic, paragraphs, tasks}
}

let list = () =>
  Http.getJson("/topics", optsNone)
  ->Promise.then(j => dArr(j)->Array.map(decodeTopic)->Promise.resolve)

let page = (~id: string) =>
  Http.getJson("/topics/" ++ id ++ "/page", optsNone)
  ->Promise.then(j => decodeTopicPage(j)->Promise.resolve)

let paragraphs = (~id: string) =>
  Http.getJson("/topics/" ++ id ++ "/paragraphs", optsNone)
  ->Promise.then(j => dArr(j)->Array.map(decodeParagraph)->Promise.resolve)
