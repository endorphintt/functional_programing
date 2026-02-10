module S = {
  @module("./Profile.module.scss") external page: string = "page"
  @module("./Profile.module.scss") external top: string = "top"
  @module("./Profile.module.scss") external h1: string = "h1"
  @module("./Profile.module.scss") external sub: string = "sub"
  @module("./Profile.module.scss") external card: string = "card"
  @module("./Profile.module.scss") external row: string = "row"
  @module("./Profile.module.scss") external label: string = "label"
  @module("./Profile.module.scss") external value: string = "value"
  @module("./Profile.module.scss") external actions: string = "actions"
  @module("./Profile.module.scss") external btn: string = "btn"
  @module("./Profile.module.scss") external danger: string = "danger"
}

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

let logout = () => {
  Token.clearToken()
  Webapi.Dom.Location.reload(Webapi.Dom.Window.location(Webapi.Dom.window))
}

@react.component
let make = () => {
  let (me, setMe) = React.useState((): option<UsersTypes.me> => None)
  let (err, setErr) = React.useState(() => "")
  let (loading, setLoading) = React.useState(() => true)

  React.useEffect0(() => {
    setLoading(_ => true)

    let _ =
      UsersApi.me()
      ->Promise.then(m => {
        setMe(_ => Some(m))
        setErr(_ => "")
        setLoading(_ => false)
        Promise.resolve()
      })
      ->Promise.catch(e => {
        setErr(_ => errMsg(e))
        setLoading(_ => false)
        Promise.resolve()
      })

    None
  })

  <div className={S.page}>
    <div className={S.top}>
      <div>
        <div className={S.h1}>{"Profile"->React.string}</div>
        <div className={S.sub}>
          {switch loading {
           | true => "Loading..."->React.string
           | false =>
             switch me {
             | Some(m) => ("Signed in as " ++ m.nickname)->React.string
             | None => "Not loaded"->React.string
             }
           }}
        </div>
      </div>

      <button className={S.btn ++ " " ++ S.danger} onClick={_ => logout()}>
        {"Logout"->React.string}
      </button>
    </div>

    {switch err {
     | "" => React.null
     | msg => <div className={S.sub}>{("Error: " ++ msg)->React.string}</div>
     }}

    {switch me {
     | None => React.null
     | Some(m) =>
         <div className={S.card}>
           <div className={S.row}>
             <div className={S.label}>{"Nickname"->React.string}</div>
             <div className={S.value}>{m.nickname->React.string}</div>
           </div>

           <div className={S.row}>
             <div className={S.label}>{"Email"->React.string}</div>
             <div className={S.value}>{m.email->React.string}</div>
           </div>

           <div className={S.row}>
             <div className={S.label}>{"Role"->React.string}</div>
             <div className={S.value}>{m.role->React.string}</div>
           </div>

           <div className={S.row}>
             <div className={S.label}>{"Rating"->React.string}</div>
             <div className={S.value}>{m.rating->Int.toString->React.string}</div>
           </div>

           <div className={S.row}>
             <div className={S.label}>{"ID"->React.string}</div>
             <div className={S.value}>{m.id->React.string}</div>
           </div>
         </div>
     }}
  </div>
}
