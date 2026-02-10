module S = {
  @module("./TaskSubmissions.module.scss") external page: string = "page"
  @module("./TaskSubmissions.module.scss") external top: string = "top"
  @module("./TaskSubmissions.module.scss") external h1: string = "h1"
  @module("./TaskSubmissions.module.scss") external sub: string = "sub"
  @module("./TaskSubmissions.module.scss") external card: string = "card"
  @module("./TaskSubmissions.module.scss") external row: string = "row"
  @module("./TaskSubmissions.module.scss") external left: string = "left"
  @module("./TaskSubmissions.module.scss") external title: string = "title"
  @module("./TaskSubmissions.module.scss") external meta: string = "meta"
  @module("./TaskSubmissions.module.scss") external right: string = "right"
  @module("./TaskSubmissions.module.scss") external badge: string = "badge"
  @module("./TaskSubmissions.module.scss") external btn: string = "btn"
}

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

@react.component
let make = (~taskId: string) => {
  let (items, setItems) = React.useState((): array<TasksTypes.mySubmissionItem> => [])
  let (err, setErr) = React.useState(() => "")
  let (loading, setLoading) = React.useState(() => true)

  React.useEffect1(() => {
    if taskId == "" {
      setLoading(_ => false)
      None
    } else {
      setLoading(_ => true)

      let _ =
        TasksApi.mySubmissions(~id=taskId, ~limit=?Some(50), ~offset=?Some(0))
        ->Promise.then(r => {
          setItems(_ => r.items)
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
  }, [taskId])

  <div className={S.page}>
    <div className={S.top}>
      <div>
        <div className={S.h1}>{"My submissions"->React.string}</div>
        <div className={S.sub}>
          {switch loading {
           | true => "Loading..."->React.string
           | false => ("Task id: " ++ taskId)->React.string
           }}
        </div>
      </div>

      <NextLink href={"/task/" ++ taskId} className={S.btn}>
        {"Back"->React.string}
      </NextLink>
    </div>

    {switch err {
     | "" => React.null
     | msg => <div className={S.sub}>{("Error: " ++ msg)->React.string}</div>
     }}

    <div className={S.card}>
      {items
       ->Belt.Array.mapWithIndex(((i, it) =>
         <div className={S.row} key={it.id}>
           <div className={S.left}>
             <div className={S.title}>
               {("#" ++ (i + 1)->Int.toString ++ " • " ++ it.created_at)->React.string}
             </div>
             <div className={S.meta}>
               {("score " ++ it.score->Int.toString
                 ++ " • " ++ it.passed_tests->Int.toString
                 ++ "/" ++ it.total_tests->Int.toString)->React.string}
             </div>
           </div>

           <div className={S.right}>
             <div className={S.badge}>{it.status->React.string}</div>
             <NextLink href={"/submission/" ++ it.id} className={S.btn}>
               {"Open"->React.string}
             </NextLink>
           </div>
         </div>
       ))
       ->React.array}
    </div>
  </div>
}
