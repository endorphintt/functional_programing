open UsersTypes

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

let dArr = (o: Dict.t<JSON.t>, k: string): array<JSON.t> =>
  switch Dict.get(o, k)->Belt.Option.flatMap(JSON.Decode.array) {
  | Some(v) => v
  | None => JsError.throwWithMessage("missing " ++ k)
  }

let decodeMe = (j: JSON.t): me => {
  let o = dObj(j)
  {
    id: dStr(o, "id"),
    email: dStr(o, "email"),
    nickname: dStr(o, "nickname"),
    role: dStr(o, "role"),
    rating: dInt(o, "rating"),
  }
}

let decodeLeaderboardItem = (j: JSON.t): leaderboardItem => {
  let o = dObj(j)
  {
    id: dStr(o, "id"),
    email: dStr(o, "email"),
    nickname: dStr(o, "nickname"),
    rating: dInt(o, "rating"),
  }
}

let decodeLeaderboard = (j: JSON.t): leaderboard => {
  let o = dObj(j)
  let items = dArr(o, "items")->Array.map(decodeLeaderboardItem)
  {limit: dInt(o, "limit"), offset: dInt(o, "offset"), items}
}

let me = () =>
  Http.getJson(UsersConstants.base ++ "/me", authOpts())
  ->Promise.then(j => decodeMe(j)->Promise.resolve)

let leaderboard = (~limit: option<int>=?, ~offset: option<int>=?) => {
  let q =
    switch (limit, offset) {
    | (None, None) => ""
    | _ =>
      let l = switch limit { | Some(v) => "limit=" ++ v->Int.toString | None => "" }
      let o = switch offset { | Some(v) => "offset=" ++ v->Int.toString | None => "" }
      let sep = if l != "" && o != "" { "&" } else { "" }
      "?" ++ l ++ sep ++ o
    }

  Http.getJson(UsersConstants.base ++ "/leaderboard" ++ q, optsNone)
  ->Promise.then(j => decodeLeaderboard(j)->Promise.resolve)
}
