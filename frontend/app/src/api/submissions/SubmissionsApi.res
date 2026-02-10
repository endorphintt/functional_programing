open SubmissionsTypes

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

let dInt = (o: Dict.t<JSON.t>, k: string): int =>
  switch Dict.get(o, k)->Belt.Option.flatMap(JSON.Decode.float) {
  | Some(v) => v->Float.toInt
  | None => JsError.throwWithMessage("missing " ++ k)
  }

let dAny = (o: Dict.t<JSON.t>, k: string): JSON.t =>
  switch Dict.get(o, k) {
  | Some(v) => v
  | None => JsError.throwWithMessage("missing " ++ k)
  }

let decodeSubmission = (j: JSON.t): submission => {
  let o = dObj(j)
  {
    id: dStr(o, "id"),
    status: dStr(o, "status"),
    score: dInt(o, "score"),
    passed_tests: dInt(o, "passed_tests"),
    total_tests: dInt(o, "total_tests"),
    result: dAny(o, "result"),
  }
}

let getOne = (~id: string) =>
  Http.getJson("/submissions/" ++ id, authOpts())
  ->Promise.then(j => decodeSubmission(j)->Promise.resolve)
