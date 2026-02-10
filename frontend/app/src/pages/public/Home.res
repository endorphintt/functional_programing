module S = {
  @module("./Home.module.scss") external page: string = "page"
  @module("./Home.module.scss") external top: string = "top"
  @module("./Home.module.scss") external h1: string = "h1"
  @module("./Home.module.scss") external sub: string = "sub"
  @module("./Home.module.scss") external grid: string = "grid"
  @module("./Home.module.scss") external card: string = "card"
  @module("./Home.module.scss") external cardTitle: string = "cardTitle"
  @module("./Home.module.scss") external cardMeta: string = "cardMeta"
}

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

@react.component
let make = () => {
  let (topics, setTopics) = React.useState((): array<TopicsTypes.topic> => [])
  let (err, setErr) = React.useState(() => "")
  let (loading, setLoading) = React.useState(() => true)

  React.useEffect0(() => {
    setLoading(_ => true)

    let _ =
      TopicsApi.list()
      ->Promise.then(ts => {
        setTopics(_ => ts)
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
      <div className={S.h1}>{"Topics"->React.string}</div>
      <div className={S.sub}>
        {switch loading {
         | true => "Loading..."->React.string
         | false => (topics->Array.length->Int.toString ++ " topics")->React.string
         }}
      </div>
      {switch err {
       | "" => React.null
       | msg => <div className={S.sub}>{("Error: " ++ msg)->React.string}</div>
       }}
    </div>

    <div className={S.grid}>
      {topics
       ->Array.map(t =>
         <NextLink href={"/topic/" ++ t.id} key={t.id} className={S.card}>
           <>
             <div className={S.cardTitle}>{t.title->React.string}</div>
             <div className={S.cardMeta}>
               {(t.subtitle == "" ? "Open" : t.subtitle)->React.string}
             </div>
           </>
         </NextLink>
       )
       ->React.array}
    </div>
  </div>
}
