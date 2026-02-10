module S = {
  @module("./Admin.module.scss") external page: string = "page"
  @module("./Admin.module.scss") external top: string = "top"
  @module("./Admin.module.scss") external h1: string = "h1"
  @module("./Admin.module.scss") external sub: string = "sub"
  @module("./Admin.module.scss") external grid: string = "grid"
  @module("./Admin.module.scss") external card: string = "card"
  @module("./Admin.module.scss") external cardTitle: string = "cardTitle"
  @module("./Admin.module.scss") external cardSub: string = "cardSub"
  @module("./Admin.module.scss") external cardMeta: string = "cardMeta"
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

    <div className={S.grid}>
      <NextLink href="/admin/topics" className={S.card}>
        <div className={S.cardTitle}>{"Topics"->React.string}</div>
        <div className={S.cardSub}>{"Create topics, paragraphs, archive/unarchive."->React.string}</div>
        <div className={S.cardMeta}>{(topicsCount->Int.toString ++ " total")->React.string}</div>
      </NextLink>

      <NextLink href="/admin/tasks" className={S.card}>
        <div className={S.cardTitle}>{"Tasks"->React.string}</div>
        <div className={S.cardSub}>{"Create tasks, manage tests, archive/unarchive."->React.string}</div>
        <div className={S.cardMeta}>{(tasksCount->Int.toString ++ " total")->React.string}</div>
      </NextLink>

      <NextLink href="/admin/users" className={S.card}>
        <div className={S.cardTitle}>{"Users"->React.string}</div>
        <div className={S.cardSub}>{"Me + leaderboard pagination."->React.string}</div>
        <div className={S.cardMeta}>{("Top: " ++ topUsers->Belt.Array.length->Int.toString)->React.string}</div>
      </NextLink>

      <NextLink href="/admin/submissions" className={S.card}>
        <div className={S.cardTitle}>{"Submissions"->React.string}</div>
        <div className={S.cardSub}>{"Lookup submission by id."->React.string}</div>
        <div className={S.cardMeta}>{"By id"->React.string}</div>
      </NextLink>
    </div>
  </div>
}
