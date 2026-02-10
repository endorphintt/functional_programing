module S = {
  @module("./AdminTopics.module.scss") external page: string = "page"
  @module("./AdminTopics.module.scss") external top: string = "top"
  @module("./AdminTopics.module.scss") external h1: string = "h1"
  @module("./AdminTopics.module.scss") external sub: string = "sub"
  @module("./AdminTopics.module.scss") external btn: string = "btn"
  @module("./AdminTopics.module.scss") external card: string = "card"
  @module("./AdminTopics.module.scss") external h2: string = "h2"
  @module("./AdminTopics.module.scss") external grid: string = "grid"
  @module("./AdminTopics.module.scss") external field: string = "field"
  @module("./AdminTopics.module.scss") external label: string = "label"
  @module("./AdminTopics.module.scss") external input: string = "input"
  @module("./AdminTopics.module.scss") external row: string = "row"
  @module("./AdminTopics.module.scss") external smallBtn: string = "smallBtn"
  @module("./AdminTopics.module.scss") external pill: string = "pill"
  @module("./AdminTopics.module.scss") external error: string = "error"
  @module("./AdminTopics.module.scss") external list: string = "list"
  @module("./AdminTopics.module.scss") external item: string = "item"
  @module("./AdminTopics.module.scss") external left: string = "left"
  @module("./AdminTopics.module.scss") external title: string = "title"
  @module("./AdminTopics.module.scss") external meta: string = "meta"
  @module("./AdminTopics.module.scss") external actions: string = "actions"
  @module("./AdminTopics.module.scss") external badge: string = "badge"
}

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

let includesLower: (string, string) => bool = %raw("(s,q)=>String(s).toLowerCase().includes(String(q))")

@react.component
let make = () => {
  let (items, setItems) = React.useState((): array<AdminTopicsTypes.topicAdminListItem> => [])
  let (loading, setLoading) = React.useState(() => true)
  let (err, setErr) = React.useState(() => "")

  let (title, setTitle) = React.useState(() => "")
  let (subtitle, setSubtitle) = React.useState(() => "")
  let (creating, setCreating) = React.useState(() => false)

  let (filter, setFilter) = React.useState(() => "")
  let (showArchived, setShowArchived) = React.useState(() => false)

  let load = () => {
    setLoading(_ => true)
    setErr(_ => "")
    let _ =
      AdminTopicsApi.listAdmin()
      ->Promise.then(xs => {
        setItems(_ => xs)
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

  let onCreate = () => {
    if title->String.trim == "" {
      setErr(_ => "Title is required")
    } else {
      setCreating(_ => true)
      setErr(_ => "")
      let _ =
        AdminTopicsApi.create({title, subtitle})
        ->Promise.then(_ => {
          setTitle(_ => "")
          setSubtitle(_ => "")
          setCreating(_ => false)
          load()
          Promise.resolve()
        })
        ->Promise.catch(e => {
          setErr(_ => errMsg(e))
          setCreating(_ => false)
          Promise.resolve()
        })
    }
  }

  let onArchive = (~id: string) => {
    let _ = AdminTopicsApi.archive(~id)->Promise.then(_ => {load(); Promise.resolve()})
  }

  let onUnarchive = (~id: string) => {
    let _ = AdminTopicsApi.unarchive(~id)->Promise.then(_ => {load(); Promise.resolve()})
  }

  let q = filter->String.trim->String.toLowerCase

  let visible =
    items
    ->Belt.Array.keep(it => {
      let okArchived =
        switch (showArchived, it.archived_at) {
        | (true, _) => true
        | (false, None) => true
        | (false, Some(_)) => false
        }

      let okFilter =
        if q == "" {
          true
        } else {
          includesLower(it.title, q) || includesLower(it.subtitle, q) || includesLower(it.id, q)
        }

      okArchived && okFilter
    })

  <div className={S.page}>
    <div className={S.top}>
      <div>
        <div className={S.h1}>{"Topics (admin)"->React.string}</div>
        <div className={S.sub}>
          {switch loading {
           | true => "Loading..."->React.string
           | false => (visible->Belt.Array.length->Int.toString ++ " topics")->React.string
           }}
        </div>
        {switch err {
         | "" => React.null
         | msg => <div className={S.error}>{("Error: " ++ msg)->React.string}</div>
         }}
      </div>

      <NextLink href="/admin" className={S.btn}>{"Back"->React.string}</NextLink>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Create topic"->React.string}</div>

      <div className={S.grid}>
        <div className={S.field}>
          <div className={S.label}>{"Title"->React.string}</div>
          <input className={S.input} value={title} onChange={e => setTitle(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"Subtitle"->React.string}</div>
          <input className={S.input} value={subtitle} onChange={e => setSubtitle(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.row}>
          <button className={S.smallBtn} disabled={creating} onClick={_ => onCreate()}>
            {(creating ? "Creating..." : "Create")->React.string}
          </button>
          <button className={S.smallBtn} onClick={_ => load()} disabled={loading}>
            {(loading ? "Reloading..." : "Reload")->React.string}
          </button>
        </div>
      </div>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Topics"->React.string}</div>

      <div className={S.grid}>
        <div className={S.field}>
          <div className={S.label}>{"Filter"->React.string}</div>
          <input className={S.input} value={filter} onChange={e => setFilter(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.row}>
          <button className={S.smallBtn} onClick={_ => setShowArchived(v => !v)}>
            {(showArchived ? "Showing archived" : "Hide archived")->React.string}
          </button>
          <div className={S.pill}>
            {("Total: " ++ items->Belt.Array.length->Int.toString)->React.string}
          </div>
        </div>
      </div>

      <div className={S.list}>
        {visible
         ->Belt.Array.map(it => {
           let archived = switch it.archived_at { | None => false | Some(_) => true }
           <div className={S.item} key={it.id}>
             <div className={S.left}>
               <div className={S.title}>
                 {(it.title ++ (archived ? " (archived)" : ""))->React.string}
               </div>
               <div className={S.meta}>
                 {(it.subtitle == "" ? "—" : it.subtitle)->React.string}
               </div>
               <div className={S.meta}>
                 {("id " ++ it.id ++ " • " ++ it.created_at)->React.string}
               </div>
               {switch it.archived_at {
                | None => React.null
                | Some(s) => <div className={S.badge}>{("archived_at " ++ s)->React.string}</div>
                }}
             </div>

             <div className={S.actions}>
               {if archived {
                  <button className={S.smallBtn} onClick={_ => onUnarchive(~id=it.id)}>
                    {"Unarchive"->React.string}
                  </button>
                } else {
                  <button className={S.smallBtn} onClick={_ => onArchive(~id=it.id)}>
                    {"Archive"->React.string}
                  </button>
                }}
             </div>
           </div>
         })
         ->React.array}
      </div>
    </div>
  </div>
}
