module S = {
  @module("./Topic.module.scss") external page: string = "page"
  @module("./Topic.module.scss") external top: string = "top"
  @module("./Topic.module.scss") external h1: string = "h1"
  @module("./Topic.module.scss") external sub: string = "sub"
  @module("./Topic.module.scss") external grid: string = "grid"
  @module("./Topic.module.scss") external card: string = "card"
  @module("./Topic.module.scss") external cardTitle: string = "cardTitle"
  @module("./Topic.module.scss") external cardMeta: string = "cardMeta"
  @module("./Topic.module.scss") external btn: string = "btn"
}

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

@react.component
let make = (~topicId: string) => {
  let (tasks, setTasks) = React.useState((): array<TasksTypes.taskListItem> => [])
  let (err, setErr) = React.useState(() => "")
  let (loading, setLoading) = React.useState(() => true)

  React.useEffect1(() => {
    if topicId == "" {
      setLoading(_ => false)
      None
    } else {
      setLoading(_ => true)

      let _ =
        TasksApi.listByTopic(~topicId)
        ->Promise.then(ts => {
          setTasks(_ => ts)
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
    }
  }, [topicId])

  <div className={S.page}>
    <div className={S.top}>
      <div>
        <div className={S.h1}>{("Topic " ++ topicId)->React.string}</div>
        <div className={S.sub}>
          {switch loading {
           | true => "Loading..."->React.string
           | false => (tasks->Array.length->Int.toString ++ " tasks")->React.string
           }}
        </div>
        {switch err {
         | "" => React.null
         | msg => <div className={S.sub}>{("Error: " ++ msg)->React.string}</div>
         }}
      </div>

      <NextLink href="/" className={S.btn}>
        {"Topics"->React.string}
      </NextLink>
    </div>

    <div className={S.grid}>
      {tasks
       ->Array.map(t =>
         <NextLink href={"/task/" ++ t.id} key={t.id} className={S.card}>
           <>
             <div className={S.cardTitle}>{t.title->React.string}</div>
             <div className={S.cardMeta}>{("Open task")->React.string}</div>
           </>
         </NextLink>
       )
       ->React.array}
    </div>
  </div>
}
