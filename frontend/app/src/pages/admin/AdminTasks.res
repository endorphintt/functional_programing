module S = {
  @module("./AdminTasks.module.scss") external page: string = "page"
  @module("./AdminTasks.module.scss") external top: string = "top"
  @module("./AdminTasks.module.scss") external h1: string = "h1"
  @module("./AdminTasks.module.scss") external sub: string = "sub"
  @module("./AdminTasks.module.scss") external btn: string = "btn"
  @module("./AdminTasks.module.scss") external card: string = "card"
  @module("./AdminTasks.module.scss") external h2: string = "h2"
  @module("./AdminTasks.module.scss") external grid: string = "grid"
  @module("./AdminTasks.module.scss") external field: string = "field"
  @module("./AdminTasks.module.scss") external label: string = "label"
  @module("./AdminTasks.module.scss") external input: string = "input"
  @module("./AdminTasks.module.scss") external textarea: string = "textarea"
  @module("./AdminTasks.module.scss") external row: string = "row"
  @module("./AdminTasks.module.scss") external smallBtn: string = "smallBtn"
  @module("./AdminTasks.module.scss") external badge: string = "badge"
  @module("./AdminTasks.module.scss") external error: string = "error"
  @module("./AdminTasks.module.scss") external list: string = "list"
  @module("./AdminTasks.module.scss") external testRow: string = "testRow"
  @module("./AdminTasks.module.scss") external left: string = "left"
  @module("./AdminTasks.module.scss") external title: string = "title"
  @module("./AdminTasks.module.scss") external meta: string = "meta"
}

@module("../../shared/auth/AdminGuard.js")
external adminGuard: React.component<unit> = "default"

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

let includesLower: (string, string) => bool = %raw("(s,q)=>String(s).toLowerCase().includes(String(q))")
let jsonParse: string => JSON.t = %raw("s => globalThis.JSON.parse(s)")
let jsonStringify: JSON.t => string = %raw("v => globalThis.JSON.stringify(v, null, 2)")

let parseJson = (s: string): option<JSON.t> => {
  try {
    Some(Obj.magic(jsonParse(s)))
  } catch {
  | _ => None
  }
}

let stringifyJson = (j: JSON.t): string => jsonStringify(Obj.magic(j))

let cut = (s: string, n: int): string =>
  if s->String.length <= n {
    s
  } else {
    s->String.slice(~start=0, ~end=n) ++ "…"
  }

@react.component
let make = () => {
  let (items, setItems) = React.useState((): array<AdminTasksTypes.adminTask> => [])
  let (loading, setLoading) = React.useState(() => true)
  let (err, setErr) = React.useState(() => "")

  let (filter, setFilter) = React.useState(() => "")
  let (showArchived, setShowArchived) = React.useState(() => false)

  let (topicId, setTopicId) = React.useState(() => "")
  let (title, setTitle) = React.useState(() => "")
  let (statement, setStatement) = React.useState(() => "")
  let (starterCode, setStarterCode) = React.useState(() => "")
  let (runner, setRunner) = React.useState(() => "")
  let (runnerBody, setRunnerBody) = React.useState(() => "")
  let (creating, setCreating) = React.useState(() => false)
  let (createdId, setCreatedId) = React.useState((): option<string> => None)
  let (createErr, setCreateErr) = React.useState(() => "")

  let (selectedTaskId, setSelectedTaskId) = React.useState(() => "")
  let (tests, setTests) = React.useState((): array<AdminTestsTypes.testItem> => [])
  let (loadingTests, setLoadingTests) = React.useState(() => false)
  let (testsErr, setTestsErr) = React.useState(() => "")

  let (newName, setNewName) = React.useState(() => "")
  let (newOrder, setNewOrder) = React.useState(() => "0")
  let (newInput, setNewInput) = React.useState(() => "")
  let (newExpected, setNewExpected) = React.useState(() => "")
  let (adding, setAdding) = React.useState(() => false)

  let load = () => {
    setLoading(_ => true)
    setErr(_ => "")
    let _ =
      AdminTasksApi.list()
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

  let loadTests = (~taskId: string) => {
    if taskId == "" {
      setTests(_ => [])
      setTestsErr(_ => "")
    } else {
      setLoadingTests(_ => true)
      setTestsErr(_ => "")
      let _ =
        AdminTestsApi.list(~taskId)
        ->Promise.then(xs => {
          setTests(_ => xs)
          setLoadingTests(_ => false)
          Promise.resolve()
        })
        ->Promise.catch(e => {
          setTestsErr(_ => errMsg(e))
          setLoadingTests(_ => false)
          Promise.resolve()
        })
    }
  }

  React.useEffect0(() => {
    load()
    None
  })

  React.useEffect1(() => {
    loadTests(~taskId=selectedTaskId)
    None
  }, [selectedTaskId])

  let onCreate = () => {
    if topicId->String.trim == "" || title->String.trim == "" {
      setCreateErr(_ => "topic_id and title are required")
    } else {
      setCreating(_ => true)
      setCreateErr(_ => "")
      setCreatedId(_ => None)

      let r = runner->String.trim
      let rb = runnerBody->String.trim

      let dto: AdminTasksTypes.createTaskRequest = {
        topic_id: topicId,
        title,
        statement,
        starter_code: starterCode,
        runner: r == "" ? None : Some(r),
        runner_body: rb == "" ? None : Some(rb),
      }

      let _ =
        AdminTasksApi.create(dto)
        ->Promise.then(res => {
          setCreatedId(_ => Some(res.id))
          setSelectedTaskId(_ => res.id)
          setCreating(_ => false)
          load()
          Promise.resolve()
        })
        ->Promise.catch(e => {
          setCreateErr(_ => errMsg(e))
          setCreating(_ => false)
          Promise.resolve()
        })
    }
  }

  let onArchive = (~id: string) => {
    if id != "" {
      let _ =
        AdminTasksApi.archive(~id)
        ->Promise.then(_ => {
          load()
          Promise.resolve()
        })
        ->Promise.catch(_ => Promise.resolve())
    }
  }

  let onUnarchive = (~id: string) => {
    if id != "" {
      let _ =
        AdminTasksApi.unarchive(~id)
        ->Promise.then(_ => {
          load()
          Promise.resolve()
        })
        ->Promise.catch(_ => Promise.resolve())
    }
  }

  let onDeleteTest = (~id: string) => {
    let _ =
      AdminTestsApi.deleteOne(~testId=id)
      ->Promise.then(_ => {
        loadTests(~taskId=selectedTaskId)
        Promise.resolve()
      })
      ->Promise.catch(_ => Promise.resolve())
  }

  let onAddTest = () => {
    if selectedTaskId == "" {
      setTestsErr(_ => "Select task")
    } else {
      switch (parseJson(newInput), parseJson(newExpected)) {
      | (Some(input_json), Some(expected_json)) =>
        setAdding(_ => true)
        setTestsErr(_ => "")

        let order_index =
          switch Int.fromString(newOrder->String.trim) {
          | Some(v) => v
          | None => 0
          }

        let t: AdminTestsTypes.testIn = {
          name: newName->String.trim == "" ? "test" : newName,
          input_json,
          expected_json,
          order_index,
        }

        let _ =
          AdminTestsApi.add(~taskId=selectedTaskId, ~tests=Belt.Array.make(1, t))
          ->Promise.then(_ => {
            setNewName(_ => "")
            setNewInput(_ => "")
            setNewExpected(_ => "")
            setNewOrder(_ => "0")
            setAdding(_ => false)
            loadTests(~taskId=selectedTaskId)
            Promise.resolve()
          })
          ->Promise.catch(e => {
            setTestsErr(_ => errMsg(e))
            setAdding(_ => false)
            Promise.resolve()
          })
      | _ =>
        setTestsErr(_ => "Bad JSON in input_json or expected_json")
      }
    }
  }

  let q = filter->String.trim->String.toLowerCase

  let visible =
    items
    ->Belt.Array.keep(t => {
      let archived = switch t.archived_at { | None => false | Some(_) => true }

      let okArchived =
        switch (showArchived, archived) {
        | (true, _) => true
        | (false, false) => true
        | (false, true) => false
        }

      let okFilter =
        if q == "" {
          true
        } else {
          includesLower(t.title, q) || includesLower(t.id, q) || includesLower(t.topic_id, q)
        }

      okArchived && okFilter
    })

  <div className={S.page}>
    {React.createElement(adminGuard, ())}

    <div className={S.top}>
      <div>
        <div className={S.h1}>{"Tasks (admin)"->React.string}</div>
        <div className={S.sub}>
          {switch (loading, err) {
           | (true, _) => "Loading..."->React.string
           | (false, "") => ("Tasks: " ++ visible->Belt.Array.length->Int.toString)->React.string
           | (false, msg) => ("Error: " ++ msg)->React.string
           }}
        </div>
      </div>

      <NextLink href="/admin" className={S.btn}>{"Back"->React.string}</NextLink>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Create task"->React.string}</div>

      {switch createErr {
       | "" => React.null
       | msg => <div className={S.error}>{("Error: " ++ msg)->React.string}</div>
       }}

      <div className={S.grid}>
        <div className={S.field}>
          <div className={S.label}>{"topic_id"->React.string}</div>
          <input className={S.input} value={topicId} onChange={e => setTopicId(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"title"->React.string}</div>
          <input className={S.input} value={title} onChange={e => setTitle(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"statement"->React.string}</div>
          <textarea className={S.textarea} value={statement} onChange={e => setStatement(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"starter_code"->React.string}</div>
          <textarea className={S.textarea} value={starterCode} onChange={e => setStarterCode(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"runner (optional)"->React.string}</div>
          <input className={S.input} value={runner} onChange={e => setRunner(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"runner_body (optional)"->React.string}</div>
          <textarea className={S.textarea} value={runnerBody} onChange={e => setRunnerBody(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.row}>
          <button className={S.smallBtn} disabled={creating} onClick={_ => onCreate()}>
            {(creating ? "Creating..." : "Create")->React.string}
          </button>

          <button className={S.smallBtn} disabled={loading} onClick={_ => load()}>
            {(loading ? "Reloading..." : "Reload list")->React.string}
          </button>

          <button className={S.smallBtn} onClick={_ => setShowArchived(v => !v)}>
            {(showArchived ? "Showing archived" : "Hide archived")->React.string}
          </button>

          {switch createdId {
           | None => React.null
           | Some(id) =>
             <div className={S.row}>
               <div className={S.badge}>{("Created: " ++ id)->React.string}</div>
               <NextLink href={"/task/" ++ id} className={S.smallBtn}>{"Open task"->React.string}</NextLink>
             </div>
           }}
        </div>
      </div>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Tasks"->React.string}</div>

      <div className={S.grid}>
        <div className={S.field}>
          <div className={S.label}>{"filter"->React.string}</div>
          <input className={S.input} value={filter} onChange={e => setFilter(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"selected_task_id"->React.string}</div>
          <input className={S.input} value={selectedTaskId} onChange={e => setSelectedTaskId(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.row}>
          <div className={S.badge}>
            {("Total: " ++ items->Belt.Array.length->Int.toString)->React.string}
          </div>
        </div>
      </div>

      {switch err {
       | "" => React.null
       | msg => <div className={S.error}>{("Error: " ++ msg)->React.string}</div>
       }}

      <div className={S.list}>
        {visible
         ->Belt.Array.map(t => {
           let archived = switch t.archived_at { | None => false | Some(_) => true }
           <div className={S.testRow} key={t.id}>
             <div className={S.left}>
               <div className={S.title}>
                 {(t.title ++ (archived ? " (archived)" : ""))->React.string}
               </div>
               <div className={S.meta}>{("id " ++ t.id ++ " • topic " ++ t.topic_id)->React.string}</div>
               <div className={S.meta}>{("created_at " ++ t.created_at)->React.string}</div>
               {switch t.archived_at {
                | None => React.null
                | Some(s) => <div className={S.meta}>{("archived_at " ++ s)->React.string}</div>
                }}
             </div>

             <div className={S.row}>
               <button className={S.smallBtn} onClick={_ => setSelectedTaskId(_ => t.id)}>
                 {"Select"->React.string}
               </button>

               <NextLink href={"/task/" ++ t.id} className={S.smallBtn}>{"Open"->React.string}</NextLink>

               {if archived {
                  <button className={S.smallBtn} onClick={_ => onUnarchive(~id=t.id)}>
                    {"Unarchive"->React.string}
                  </button>
                } else {
                  <button className={S.smallBtn} onClick={_ => onArchive(~id=t.id)}>
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
      <div className={S.h2}>{"Add test"->React.string}</div>

      {switch testsErr {
       | "" => React.null
       | msg => <div className={S.error}>{("Error: " ++ msg)->React.string}</div>
       }}

      <div className={S.grid}>
        <div className={S.field}>
          <div className={S.label}>{"name"->React.string}</div>
          <input className={S.input} value={newName} onChange={e => setNewName(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"order_index"->React.string}</div>
          <input className={S.input} value={newOrder} onChange={e => setNewOrder(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"input_json"->React.string}</div>
          <textarea className={S.textarea} value={newInput} onChange={e => setNewInput(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"expected_json"->React.string}</div>
          <textarea className={S.textarea} value={newExpected} onChange={e => setNewExpected(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.row}>
          <button className={S.smallBtn} disabled={adding} onClick={_ => onAddTest()}>
            {(adding ? "Adding..." : "Add test")->React.string}
          </button>

          <button className={S.smallBtn} disabled={loadingTests} onClick={_ => loadTests(~taskId=selectedTaskId)}>
            {(loadingTests ? "Loading..." : "Reload tests")->React.string}
          </button>

          <div className={S.badge}>
            {switch selectedTaskId {
             | "" => "No task selected"->React.string
             | id => ("Task: " ++ id)->React.string
             }}
          </div>
        </div>
      </div>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Tests"->React.string}</div>

      <div className={S.sub}>
        {switch (loadingTests, selectedTaskId) {
         | (true, _) => "Loading..."->React.string
         | (false, "") => "Select task to load tests."->React.string
         | (false, _) => ("Count: " ++ tests->Belt.Array.length->Int.toString)->React.string
         }}
      </div>

      <div className={S.list}>
        {tests
         ->Belt.Array.map(t =>
           <div className={S.testRow} key={t.id}>
             <div className={S.left}>
               <div className={S.title}>{(t.name ++ " • " ++ t.id)->React.string}</div>
               <div className={S.meta}>{("input: " ++ cut(stringifyJson(t.input_json), 600))->React.string}</div>
               <div className={S.meta}>{("expected: " ++ cut(stringifyJson(t.expected_json), 600))->React.string}</div>
             </div>

             <button className={S.smallBtn} onClick={_ => onDeleteTest(~id=t.id)}>
               {"Delete"->React.string}
             </button>
           </div>
         )
         ->React.array}
      </div>
    </div>
  </div>
}
