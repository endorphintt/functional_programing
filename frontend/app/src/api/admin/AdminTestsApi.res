open AdminTestsTypes

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

let dStr = (o: Dict.t<JSON.t>, k: string): string =>
  switch Dict.get(o, k)->Belt.Option.flatMap(JSON.Decode.string) {
  | Some(v) => v
  | None => JsError.throwWithMessage("missing " ++ k)
  }

let dAny = (o: Dict.t<JSON.t>, k: string): JSON.t =>
  switch Dict.get(o, k) {
  | Some(v) => v
  | None => JsError.throwWithMessage("missing " ++ k)
  }

let decodeTestItem = (j: JSON.t): testItem => {
  let o = dObj(j)
  {
    id: dStr(o, "id"),
    task_id: dStr(o, "task_id"),
    name: dStr(o, "name"),
    input_json: dAny(o, "input_json"),
    expected_json: dAny(o, "expected_json"),
  }
}

let list = (~taskId: string) =>
  Http.getJson(AdminConstants.base ++ "/tasks/" ++ taskId ++ "/tests", authOpts())
  ->Promise.then(j =>
    switch JSON.Decode.array(j) {
    | Some(xs) => xs->Array.map(decodeTestItem)->Promise.resolve
    | None => JsError.throwWithMessage("bad json")
    }
  )

let add = (~taskId: string, ~tests: array<testIn>) => {
  let body =
    tests->Array.map(t =>
      obj([
        ("name", JSON.Encode.string(t.name)),
        ("input_json", t.input_json),
        ("expected_json", t.expected_json),
        ("order_index", JSON.Encode.int(t.order_index)),
      ])
    )
    ->JSON.Encode.array

  Http.postJson(AdminConstants.base ++ "/tasks/" ++ taskId ++ "/tests", body, authOpts())
  ->Promise.then(_ => Promise.resolve(true))
}

let deleteOne = (~testId: string) =>
  Http.deleteJson(AdminConstants.base ++ "/task-tests/" ++ testId, authOpts())
  ->Promise.then(_ => Promise.resolve(true))
