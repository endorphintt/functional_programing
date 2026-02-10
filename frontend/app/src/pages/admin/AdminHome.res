module S = {
  @module("./AdminHome.module.scss") external page: string = "page"
  @module("./AdminHome.module.scss") external top: string = "top"
  @module("./AdminHome.module.scss") external h1: string = "h1"
  @module("./AdminHome.module.scss") external sub: string = "sub"
  @module("./AdminHome.module.scss") external navCard: string = "navCard"
  @module("./AdminHome.module.scss") external navBtn: string = "navBtn"
  @module("./AdminHome.module.scss") external card: string = "card"
  @module("./AdminHome.module.scss") external h2: string = "h2"
  @module("./AdminHome.module.scss") external list: string = "list"
  @module("./AdminHome.module.scss") external item: string = "item"
  @module("./AdminHome.module.scss") external dot: string = "dot"
}

@module("../../shared/auth/AdminGuard.js")
external adminGuard: React.component<unit> = "default"

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

@react.component
let make = () => {
  let (loading, setLoading) = React.useState(() => true)
  let (err, setErr) = React.useState(() => "")

  let (topicsCount, setTopicsCount) = React.useState(() => 0)
  let (tasksCount, setTasksCount) = React.useState(() => 0)
  let (topUsers, setTopUsers) = React.useState((): array<UsersTypes.leaderboardItem> => [])

  let load = () => {
    setLoading(_ => true)
    setErr(_ => "")

    let _ =
      AdminTopicsApi.listAdmin()
      ->Promise.then(ts => {
        setTopicsCount(_ => ts->Belt.Array.length)
        AdminTasksApi.list()
      })
      ->Promise.then(tasks => {
        setTasksCount(_ => tasks->Belt.Array.length);
    UsersApi.leaderboard()
      })
      ->Promise.then(lb => {
        setTopUsers(_ => Belt.Array.slice(lb.items, ~offset=0, ~len=5))
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
    load()
    None
  })

  <div className={S.page}>
    {React.createElement(adminGuard, ())}

    <div className={S.top}>
      <div>
        <div className={S.h1}>{"Admin"->React.string}</div>
        <div className={S.sub}>
          {switch (loading, err) {
           | (true, _) => "Loading..."->React.string
           | (false, "") =>
             ("Topics: " ++ topicsCount->Int.toString ++ " • Tasks: " ++ tasksCount->Int.toString)->React.string
           | (false, msg) => ("Error: " ++ msg)->React.string
           }}
        </div>
      </div>
    </div>

    <div className={S.navCard}>
      <NextLink href="/admin/users" className={S.navBtn}>{"Users"->React.string}</NextLink>
      <NextLink href="/admin/topics" className={S.navBtn}>{"Topics"->React.string}</NextLink>
      <NextLink href="/admin/tasks" className={S.navBtn}>{"Tasks"->React.string}</NextLink>
      <NextLink href="/admin/submissions" className={S.navBtn}>{"Submissions"->React.string}</NextLink>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Overview"->React.string}</div>

      <div className={S.list}>
        <div className={S.item}><div className={S.dot} /> <div>{("topics: " ++ topicsCount->Int.toString)->React.string}</div></div>
        <div className={S.item}><div className={S.dot} /> <div>{("tasks: " ++ tasksCount->Int.toString)->React.string}</div></div>
      </div>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Top users"->React.string}</div>

      <div className={S.list}>
        {topUsers
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
