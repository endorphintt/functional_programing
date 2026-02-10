open AuthTypes

let emptyObj: Dict.t<JSON.t> = Dict.make()

let optsNone: JSON.t = JSON.Encode.object(emptyObj)

let optsSkipAuth: JSON.t = {
  let d: Dict.t<JSON.t> = Dict.make()
  Dict.set(d, "skipAuth", JSON.Encode.bool(true))
  JSON.Encode.object(d)
}

let decodeObj = (j: JSON.t): Dict.t<JSON.t> =>
  switch JSON.Decode.object(j) {
  | Some(o) => o
  | None => JsError.throwWithMessage("bad json")
  }

let getString = (o: Dict.t<JSON.t>, k: string): string =>
  switch Dict.get(o, k)->Belt.Option.flatMap(JSON.Decode.string) {
  | Some(s) => s
  | None => JsError.throwWithMessage("missing " ++ k)
  }

let getInt = (o: Dict.t<JSON.t>, k: string): int =>
  switch Dict.get(o, k)->Belt.Option.flatMap(JSON.Decode.float) {
  | Some(n) => Float.toInt(n)
  | None => JsError.throwWithMessage("missing " ++ k)
  }

let decodeAuthResponse = (j: JSON.t): authResponse => {
  let o = decodeObj(j)
  {token: getString(o, "token")}
}

let decodeMe = (j: JSON.t): me => {
  let o = decodeObj(j)
  {
    id: getString(o, "id"),
    role: getString(o, "role"),
    email: getString(o, "email"),
    nickname: getString(o, "nickname"),
    rating: getInt(o, "rating"),
  }
}

let login = (dto: loginRequest) => {
  let d: Dict.t<JSON.t> = Dict.make()
  Dict.set(d, "email", JSON.Encode.string(dto.email))
  Dict.set(d, "password", JSON.Encode.string(dto.password))
  let body = JSON.Encode.object(d)

  Http.postJson(AuthConstants.authApiBase ++ "/login", body, optsSkipAuth)
  ->Promise.then(j => Promise.resolve(decodeAuthResponse(j)))
}

let register = (dto: registerRequest) => {
  let d: Dict.t<JSON.t> = Dict.make()
  Dict.set(d, "email", JSON.Encode.string(dto.email))
  Dict.set(d, "password", JSON.Encode.string(dto.password))
  Dict.set(d, "nickname", JSON.Encode.string(dto.nickname))
  let body = JSON.Encode.object(d)

  Http.postJson(AuthConstants.authApiBase ++ "/register", body, optsSkipAuth)
  ->Promise.then(j => Promise.resolve(decodeAuthResponse(j)))
}

let me = (~token: string) => {
  let d: Dict.t<JSON.t> = Dict.make()
  Dict.set(d, "authToken", JSON.Encode.string(token))
  let opts = JSON.Encode.object(d)

  Http.getJson(AuthConstants.authApiBase ++ "/me", opts)
  ->Promise.then(j => Promise.resolve(decodeMe(j)))
}
