module S = {
  @module("./Leaderboard.module.scss") external page: string = "page"
  @module("./Leaderboard.module.scss") external top: string = "top"
  @module("./Leaderboard.module.scss") external h1: string = "h1"
  @module("./Leaderboard.module.scss") external sub: string = "sub"
  @module("./Leaderboard.module.scss") external card: string = "card"
  @module("./Leaderboard.module.scss") external row: string = "row"
  @module("./Leaderboard.module.scss") external head: string = "head"
  @module("./Leaderboard.module.scss") external rank: string = "rank"
  @module("./Leaderboard.module.scss") external name: string = "name"
  @module("./Leaderboard.module.scss") external rating: string = "rating"
}

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

@react.component
let make = () => {
  let (items, setItems) = React.useState((): array<UsersTypes.leaderboardItem> => [])
  let (err, setErr) = React.useState(() => "")
  let (loading, setLoading) = React.useState(() => true)

  React.useEffect0(() => {
    setLoading(_ => true)

    let _ =
      UsersApi.leaderboard()
      ->Promise.then(lb => {
        setItems(_ => lb.items)
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
        <div className={S.h1}>{"Leaderboard"->React.string}</div>
        <div className={S.sub}>
          {switch loading {
           | true => "Loading..."->React.string
           | false => "Top users by rating"->React.string
           }}
        </div>
      </div>
    </div>

    {switch err {
     | "" => React.null
     | msg => <div className={S.sub}>{("Error: " ++ msg)->React.string}</div>
     }}

    <div className={S.card}>
      <div className={S.row ++ " " ++ S.head}>
        <div className={S.rank}>{"#"->React.string}</div>
        <div className={S.name}>{"User"->React.string}</div>
        <div className={S.rating}>{"Rating"->React.string}</div>
      </div>

      {items
       ->Belt.Array.mapWithIndex(((i, u) =>
         <div className={S.row} key={u.id}>
           <div className={S.rank}>{(i + 1)->Int.toString->React.string}</div>
           <div className={S.name}>{u.nickname->React.string}</div>
           <div className={S.rating}>{u.rating->Int.toString->React.string}</div>
         </div>
       ))
       ->React.array}
    </div>
  </div>
}
