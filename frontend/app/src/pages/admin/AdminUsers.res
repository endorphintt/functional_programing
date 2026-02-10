module S = {
  @module("./AdminUsers.module.scss") external page: string = "page"
  @module("./AdminUsers.module.scss") external top: string = "top"
  @module("./AdminUsers.module.scss") external h1: string = "h1"
  @module("./AdminUsers.module.scss") external sub: string = "sub"
  @module("./AdminUsers.module.scss") external btn: string = "btn"
  @module("./AdminUsers.module.scss") external card: string = "card"
  @module("./AdminUsers.module.scss") external h2: string = "h2"
  @module("./AdminUsers.module.scss") external list: string = "list"
  @module("./AdminUsers.module.scss") external item: string = "item"
  @module("./AdminUsers.module.scss") external dot: string = "dot"
  @module("./AdminUsers.module.scss") external row: string = "row"
  @module("./AdminUsers.module.scss") external input: string = "input"
  @module("./AdminUsers.module.scss") external smallBtn: string = "smallBtn"
  @module("./AdminUsers.module.scss") external pill: string = "pill"
  @module("./AdminUsers.module.scss") external error: string = "error"
}

@module("../../shared/auth/AdminGuard.js")
external adminGuard: React.component<unit> = "default"

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

let parseInt = (s: string): option<int> =>
  switch Int.fromString(s->String.trim) {
  | Some(v) => Some(v)
  | None => None
  }

@react.component
let make = () => {
  let (me, setMe) = React.useState((): option<UsersTypes.me> => None)
  let (items, setItems) = React.useState((): array<UsersTypes.leaderboardItem> => [])
  let (loading, setLoading) = React.useState(() => true)
  let (err, setErr) = React.useState(() => "")

  let (limit, setLimit) = React.useState(() => 25)
  let (offset, setOffset) = React.useState(() => 0)

  let load = (~limit: int, ~offset: int) => {
    setLoading(_ => true)
    setErr(_ => "")

    let _ =
      UsersApi.me()
      ->Promise.then(m => {
        setMe(_ => Some(m))
        UsersApi.leaderboard(~limit, ~offset)
      })
      ->Promise.then(lb => {
        setItems(_ => lb.items)
        setLoading(_ => false)
        Promise.resolve()
      })
      ->Promise.catch(e => {
        setErr(_ => errMsg(e))
        setLoading(_ => false)
        Promise.resolve()
      })
  }

  React.useEffect0(() => {
    load(~limit, ~offset)
    None
  })

  let onPrev = () => {
    let nextOffset = if (0) > (offset - limit) { (0) } else { (offset - limit) }
    setOffset(_ => nextOffset)
    load(~limit, ~offset=nextOffset)
  }

  let onNext = () => {
    let nextOffset = offset + limit
    setOffset(_ => nextOffset)
    load(~limit, ~offset=nextOffset)
  }

  <div className={S.page}>
    {React.createElement(adminGuard, ())}

    <div className={S.top}>
      <div>
        <div className={S.h1}>{"Users"->React.string}</div>
        <div className={S.sub}>
          {switch (loading, err) {
           | (true, _) => "Loading..."->React.string
           | (false, "") => ("Rows: " ++ items->Belt.Array.length->Int.toString)->React.string
           | (false, msg) => ("Error: " ++ msg)->React.string
           }}
        </div>
      </div>

      <NextLink href="/admin" className={S.btn}>{"Back"->React.string}</NextLink>
    </div>

    {switch err {
     | "" => React.null
     | msg => <div className={S.error}>{("Error: " ++ msg)->React.string}</div>
     }}

    <div className={S.card}>
      <div className={S.h2}>{"Me"->React.string}</div>

      <div className={S.list}>
        {switch me {
         | None => <div className={S.item}><div className={S.dot} /> <div>{"—"->React.string}</div></div>
         | Some(m) =>
           <>
             <div className={S.item}><div className={S.dot} /> <div>{("nickname: " ++ m.nickname)->React.string}</div></div>
             <div className={S.item}><div className={S.dot} /> <div>{("email: " ++ m.email)->React.string}</div></div>
             <div className={S.item}><div className={S.dot} /> <div>{("role: " ++ m.role)->React.string}</div></div>
             <div className={S.item}><div className={S.dot} /> <div>{("rating: " ++ m.rating->Int.toString)->React.string}</div></div>
           </>
         }}
      </div>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Leaderboard"->React.string}</div>

      <div className={S.row}>
        <div className={S.pill}>{("offset " ++ offset->Int.toString)->React.string}</div>
        <div className={S.pill}>{("limit " ++ limit->Int.toString)->React.string}</div>
      </div>

      <div className={S.row}>
        <div className={S.pill}>{"limit"->React.string}</div>
        <input
          className={S.input}
          value={limit->Int.toString}
          onChange={e =>
            switch parseInt(ReactEvent.Form.target(e)["value"]) {
            | None => ()
            | Some(v) => setLimit(_ => if (1) > (v) { (1) } else { (v) })
            }
          }
        />

        <div className={S.pill}>{"offset"->React.string}</div>
        <input
          className={S.input}
          value={offset->Int.toString}
          onChange={e =>
            switch parseInt(ReactEvent.Form.target(e)["value"]) {
            | None => ()
            | Some(v) => setOffset(_ => if (0) > (v) { (0) } else { (v) })
            }
          }
        />

        <button className={S.smallBtn} onClick={_ => load(~limit, ~offset)} disabled={loading}>
          {(loading ? "Reloading..." : "Apply")->React.string}
        </button>

        <button className={S.smallBtn} onClick={_ => onPrev()} disabled={loading || offset == 0}>
          {"Prev"->React.string}
        </button>

        <button className={S.smallBtn} onClick={_ => onNext()} disabled={loading}>
          {"Next"->React.string}
        </button>
      </div>

      <div className={S.list}>
        {items
         ->Belt.Array.map(u =>
           <div className={S.item} key={u.id}>
             <div className={S.dot} />
             <div>{(u.nickname ++ " • " ++ u.rating->Int.toString)->React.string}</div>
           </div>
         )
         ->React.array}
      </div>
    </div>
  </div>
}
