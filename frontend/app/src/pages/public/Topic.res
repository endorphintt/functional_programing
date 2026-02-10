module S = {
  @module("./Topic.module.scss") external page: string = "page"
  @module("./Topic.module.scss") external top: string = "top"
  @module("./Topic.module.scss") external h1: string = "h1"
  @module("./Topic.module.scss") external sub: string = "sub"
  @module("./Topic.module.scss") external btn: string = "btn"
  @module("./Topic.module.scss") external card: string = "card"
  @module("./Topic.module.scss") external h2: string = "h2"
  @module("./Topic.module.scss") external list: string = "list"
  @module("./Topic.module.scss") external p: string = "p"
  @module("./Topic.module.scss") external pMeta: string = "pMeta"
  @module("./Topic.module.scss") external pIndex: string = "pIndex"
  @module("./Topic.module.scss") external pBody: string = "pBody"
  @module("./Topic.module.scss") external code: string = "code"
  @module("./Topic.module.scss") external tasksGrid: string = "tasksGrid"
  @module("./Topic.module.scss") external taskCard: string = "taskCard"
  @module("./Topic.module.scss") external taskTitle: string = "taskTitle"
  @module("./Topic.module.scss") external taskMeta: string = "taskMeta"
}

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

let sortParagraphs: array<TopicsTypes.paragraph> => array<TopicsTypes.paragraph> = %raw(`(xs) => {
  const ys = xs.slice();
  ys.sort((a,b) => (a.sort_key|0) - (b.sort_key|0));
  return ys;
}`)


@react.component
let make = (~topicId: string) => {
  let (page, setPage) = React.useState((): option<TopicsTypes.topicPage> => None)
  let (err, setErr) = React.useState(() => "")
  let (loading, setLoading) = React.useState(() => true)

  React.useEffect1(() => {
    if topicId == "" {
      setPage(_ => None)
      setErr(_ => "")
      setLoading(_ => false)
      None
    } else {
      setLoading(_ => true)
      setErr(_ => "")

      let _ =
        TopicsApi.page(~id=topicId)
        ->Promise.then(p => {
          setPage(_ => Some(p))
          setErr(_ => "")
          setLoading(_ => false)
          Promise.resolve()
        })
        ->Promise.catch(e => {
          setErr(_ => errMsg(e))
          setPage(_ => None)
          setLoading(_ => false)
          Promise.resolve()
        })

      None
    }
  }, [topicId])

  let title =
    switch page {
    | None => "Topic " ++ topicId
    | Some(p) => p.topic.title
    }

  let subtitle =
    switch (page, loading, err) {
    | (_, true, _) => "Loading..."
    | (_, false, msg) if msg != "" => "Error: " ++ msg
    | (None, false, _) => "No data"
    | (Some(p), false, _) =>
      p.paragraphs->Belt.Array.length->Int.toString ++ " paragraphs • " ++ p.tasks->Belt.Array.length->Int.toString ++ " tasks"
    }

  <div className={S.page}>
    <div className={S.top}>
      <div>
        <div className={S.h1}>{title->React.string}</div>
        <div className={S.sub}>{subtitle->React.string}</div>
      </div>

      <NextLink href="/" className={S.btn}>
        {"Topics"->React.string}
      </NextLink>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Paragraphs"->React.string}</div>

      {switch page {
       | None =>
         <div className={S.sub}>
           {switch loading {
            | true => "Loading..."->React.string
            | false => (err != "" ? ("Error: " ++ err) : "No paragraphs")->React.string
            }}
         </div>
       | Some(p) =>
         <div className={S.list}>
           {p.paragraphs
            ->sortParagraphs
            ->Belt.Array.map(pp =>
              <div className={S.p} key={pp.id}>
                <div className={S.pMeta}>
                  <div className={S.pIndex}>{""->React.string}</div>
                </div>

                <div className={S.pBody}>{pp.body->React.string}</div>

                {switch pp.code {
                 | None => React.null
                 | Some(c) => <pre className={S.code}>{c->React.string}</pre>
                 }}
              </div>
            )
            ->React.array}
         </div>
      }}
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Tasks"->React.string}</div>

      {switch page {
       | None =>
         <div className={S.sub}>
           {switch loading {
            | true => "Loading..."->React.string
            | false => (err != "" ? ("Error: " ++ err) : "No tasks")->React.string
            }}
         </div>
       | Some(p) =>
         <div className={S.tasksGrid}>
           {p.tasks
            ->Belt.Array.map(t =>
              <NextLink href={"/task/" ++ t.id} key={t.id} className={S.taskCard}>
                <>
                  <div className={S.taskTitle}>{t.title->React.string}</div>
                  <div className={S.taskMeta}>{("Open task")->React.string}</div>
                </>
              </NextLink>
            )
            ->React.array}
         </div>
      }}
    </div>
  </div>
}
