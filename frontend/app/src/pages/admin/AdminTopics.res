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
  @module("./AdminTopics.module.scss") external textarea: string = "textarea"
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

@module("../../shared/auth/AdminGuard.js")
external adminGuard: React.component<unit> = "default"

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

let includesLower: (string, string) => bool = %raw("(s,q)=>String(s).toLowerCase().includes(String(q))")
let cut: (string, int) => string = %raw("(s,n)=>{s=String(s||'');return s.length<=n?s:(s.slice(0,n)+'…')}")

let parseInt = (s: string): option<int> =>
  switch Int.fromString(s->String.trim) {
  | Some(v) => Some(v)
  | None => None
  }

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

  let (selectedId, setSelectedId) = React.useState((): option<string> => None)
  let (page, setPage) = React.useState((): option<AdminTopicsTypes.topicPageAdmin> => None)
  let (loadingPage, setLoadingPage) = React.useState(() => false)
  let (pageErr, setPageErr) = React.useState(() => "")

  let (pSortKey, setPSortKey) = React.useState(() => "0")
  let (pBody, setPBody) = React.useState(() => "")
  let (pCode, setPCode) = React.useState(() => "")
  let (addingP, setAddingP) = React.useState(() => false)

  let loadList = () => {
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

  let loadPage = (~id: string) => {
    setLoadingPage(_ => true)
    setPageErr(_ => "")
    setPage(_ => None)
    let _ =
      AdminTopicsApi.pageAdmin(~id)
      ->Promise.then(p => {
        setPage(_ => Some(p))
        setLoadingPage(_ => false)
        Promise.resolve()
      })
      ->Promise.catch(e => {
        setPageErr(_ => errMsg(e))
        setLoadingPage(_ => false)
        Promise.resolve()
      })
  }

  React.useEffect0(() => {
    loadList()
    None
  })

  React.useEffect1(() => {
    switch selectedId {
    | None => setPage(_ => None)
    | Some(id) => loadPage(~id)
    }
    None
  }, [selectedId])

  let onCreate = () => {
    if title->String.trim == "" {
      setErr(_ => "Title is required")
    } else {
      setCreating(_ => true)
      setErr(_ => "")
      let _ =
        AdminTopicsApi.create({title, subtitle})
        ->Promise.then(r => {
          setTitle(_ => "")
          setSubtitle(_ => "")
          setCreating(_ => false)
          loadList()
          setSelectedId(_ => Some(r.id))
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
    let _ = AdminTopicsApi.archive(~id)->Promise.then(_ => {loadList(); Promise.resolve()})
  }

  let onUnarchive = (~id: string) => {
    let _ = AdminTopicsApi.unarchive(~id)->Promise.then(_ => {loadList(); Promise.resolve()})
  }

  let onAddParagraph = () => {
    switch selectedId {
    | None => setPageErr(_ => "Select a topic")
    | Some(tid) =>
      switch parseInt(pSortKey) {
      | None => setPageErr(_ => "Bad sort_key")
      | Some(sort_key) =>
        if pBody->String.trim == "" {
          setPageErr(_ => "Body is required")
        } else {
          setAddingP(_ => true)
          setPageErr(_ => "")
          let code = pCode->String.trim == "" ? None : Some(pCode)
          let p: AdminTopicsTypes.paragraphIn = {sort_key, body: pBody, code}
          let _ =
            AdminTopicsApi.addParagraphs(~id=tid, ~items=[p])
            ->Promise.then(_ => {
              setPSortKey(_ => "0")
              setPBody(_ => "")
              setPCode(_ => "")
              setAddingP(_ => false)
              loadPage(~id=tid)
              Promise.resolve()
            })
            ->Promise.catch(e => {
              setPageErr(_ => errMsg(e))
              setAddingP(_ => false)
              Promise.resolve()
            })
        }
      }
    }
  }

  let onDeleteParagraph = (~pid: string) => {
    switch selectedId {
    | None => ()
    | Some(tid) =>
      let _ =
        AdminTopicsApi.deleteParagraph(~id=pid)
        ->Promise.then(_ => {
          loadPage(~id=tid)
          Promise.resolve()
        })
    }
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
    {React.createElement(adminGuard, ())}
    {React.createElement(adminGuard, ())}

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
          <button className={S.smallBtn} onClick={_ => loadList()} disabled={loading}>
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
           let selected = switch selectedId { | Some(id) => id == it.id | None => false }

           <div className={S.item} key={it.id} onClick={_ => setSelectedId(_ => Some(it.id))}>
             <div className={S.left}>
               <div className={S.title}>
                 {(it.title ++ (selected ? " • selected" : "") ++ (archived ? " (archived)" : ""))->React.string}
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

             <div className={S.actions} onClick={e => ReactEvent.Mouse.stopPropagation(e)}>
               <button className={S.smallBtn} onClick={_ => setSelectedId(_ => Some(it.id))}>
                 {"Open"->React.string}
               </button>

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

    <div className={S.card}>
      <div className={S.h2}>{"Topic details"->React.string}</div>

      <div className={S.sub}>
        {switch (selectedId, loadingPage, pageErr) {
         | (None, _, _) => "Select a topic to manage paragraphs."->React.string
         | (Some(id), true, _) => ("Loading " ++ id ++ "...")->React.string
         | (Some(_), false, "") =>
           switch page {
           | None => "No data"->React.string
           | Some(p) =>
             ("Paragraphs: " ++ p.paragraphs->Belt.Array.length->Int.toString ++ " • Tasks: " ++ p.tasks->Belt.Array.length->Int.toString)->React.string
           }
         | (Some(_), false, msg) => ("Error: " ++ msg)->React.string
         }}
      </div>

      {switch pageErr {
       | "" => React.null
       | msg => <div className={S.error}>{("Error: " ++ msg)->React.string}</div>
       }}

      {switch page {
       | None => React.null
       | Some(p) =>
         <div className={S.grid}>
           <div className={S.field}>
             <div className={S.label}>{"sort_key"->React.string}</div>
             <input className={S.input} value={pSortKey} onChange={e => setPSortKey(_ => ReactEvent.Form.target(e)["value"])} />
           </div>

           <div className={S.field}>
             <div className={S.label}>{"body"->React.string}</div>
             <textarea className={S.textarea} value={pBody} onChange={e => setPBody(_ => ReactEvent.Form.target(e)["value"])} />
           </div>

           <div className={S.field}>
             <div className={S.label}>{"code (optional)"->React.string}</div>
             <textarea className={S.textarea} value={pCode} onChange={e => setPCode(_ => ReactEvent.Form.target(e)["value"])} />
           </div>

           <div className={S.row}>
             <button className={S.smallBtn} disabled={addingP || loadingPage} onClick={_ => onAddParagraph()}>
               {(addingP ? "Adding..." : "Add paragraph")->React.string}
             </button>
             <button className={S.smallBtn} disabled={loadingPage} onClick={_ => loadPage(~id=p.topic.id)}>
               {"Reload details"->React.string}
             </button>
           </div>

           <div className={S.h2}>{"Paragraphs"->React.string}</div>

           <div className={S.list}>
             {p.paragraphs
              ->Belt.Array.map(pp =>
                <div className={S.item} key={pp.id}>
                  <div className={S.left}>
                    <div className={S.title}>{(pp.sort_key->Int.toString ++ " • " ++ pp.id)->React.string}</div>
                    <div className={S.meta}>{cut(pp.body, 220)->React.string}</div>
                    {switch pp.code {
                     | None => <div className={S.meta}>{"code: —"->React.string}</div>
                     | Some(c) => <div className={S.meta}>{("code: " ++ cut(c, 140))->React.string}</div>
                     }}
                  </div>

                  <div className={S.actions}>
                    <button className={S.smallBtn} onClick={_ => onDeleteParagraph(~pid=pp.id)}>
                      {"Delete"->React.string}
                    </button>
                  </div>
                </div>
              )
              ->React.array}
           </div>

           <div className={S.h2}>{"Tasks"->React.string}</div>

           <div className={S.list}>
             {p.tasks
              ->Belt.Array.map(t =>
                <div className={S.item} key={t.id}>
                  <div className={S.left}>
                    <div className={S.title}>{t.title->React.string}</div>
                    <div className={S.meta}>{("id " ++ t.id ++ " • " ++ t.created_at)->React.string}</div>
                  </div>
                  <div className={S.actions}>
                    <NextLink href={"/task/" ++ t.id} className={S.smallBtn}>{"Open"->React.string}</NextLink>
                  </div>
                </div>
              )
              ->React.array}
           </div>
           </div>
        }}
      </div>
    </div>
  }
