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

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

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

@react.component
let make = () => {
  let (title, setTitle) = React.useState(() => "")
  let (statement, setStatement) = React.useState(() => "")
  let (starterCode, setStarterCode) = React.useState(() => "")
  let (topicId, setTopicId) = React.useState(() => "1")
  let (creating, setCreating) = React.useState(() => false)
  let (createdId, setCreatedId) = React.useState((): option<string> => None)
  let (createErr, setCreateErr) = React.useState(() => "")

  let (taskId, setTaskId) = React.useState(() => "")
  let (tests, setTests) = React.useState((): array<AdminTestsTypes.testItem> => [])
  let (loadingTests, setLoadingTests) = React.useState(() => false)
  let (testsErr, setTestsErr) = React.useState(() => "")

  let (newName, setNewName) = React.useState(() => "")
  let (newOrder, setNewOrder) = React.useState(() => "0")
  let (newInput, setNewInput) = React.useState(() => "")
  let (newExpected, setNewExpected) = React.useState(() => "")
  let (adding, setAdding) = React.useState(() => false)

  let loadTests = (~id: string) => {
    if id == "" {
      setTests(_ => [])
      setTestsErr(_ => "")
    } else {
      setLoadingTests(_ => true)
      setTestsErr(_ => "")
      let _ =
        AdminTestsApi.list(~taskId=id)
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

  React.useEffect1(() => {
    loadTests(~id=taskId)
    None
  }, [taskId])

  let onCreate = () => {
    setCreating(_ => true)
    setCreateErr(_ => "")
    setCreatedId(_ => None)

    let dto: AdminTasksTypes.createTaskRequest = {
  topic_id: topicId,
  title,
  statement,
  starter_code: starterCode,
  runner: None,
  runner_body: None,
}

    let _ =
      AdminTasksApi.create(dto)
      ->Promise.then(r => {
        setCreatedId(_ => Some(r.id))
        setTaskId(_ => r.id)
        setCreating(_ => false)
        Promise.resolve()
      })
      ->Promise.catch(e => {
        setCreateErr(_ => errMsg(e))
        setCreating(_ => false)
        Promise.resolve()
      })
  }

  let onArchive = (~id: string) => {
    if id != "" {
      let _ = AdminTasksApi.archive(~id)->Promise.then(_ => Promise.resolve())
    }
  }

  let onUnarchive = (~id: string) => {
    if id != "" {
      let _ = AdminTasksApi.unarchive(~id)->Promise.then(_ => Promise.resolve())
    }
  }

  let onDeleteTest = (~id: string) => {
    let _ =
      AdminTestsApi.deleteOne(~testId=id)
      ->Promise.then(_ => {
        loadTests(~id=taskId)
        Promise.resolve()
      })
  }

  let onAddTest = () => {
    if taskId == "" {
      setTestsErr(_ => "Task id is required")
    } else {
      switch (parseJson(newInput), parseJson(newExpected)) {
      | (Some(input_json), Some(expected_json)) =>
        setAdding(_ => true)
        setTestsErr(_ => "")

        let order_index =
          switch Int.fromString(newOrder) {
          | Some(v) => v
          | None => 0
          }

        let t: AdminTestsTypes.testIn = {
          name: newName == "" ? "test" : newName,
          input_json,
          expected_json,
          order_index,
        }

        let _ =
          AdminTestsApi.add(~taskId=taskId, ~tests=Belt.Array.make(1, t))
          ->Promise.then(_ => {
            setNewName(_ => "")
            setNewInput(_ => "")
            setNewExpected(_ => "")
            setNewOrder(_ => "0")
            setAdding(_ => false)
            loadTests(~id=taskId)
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

  <div className={S.page}>
    <div className={S.top}>
      <div>
        <div className={S.h1}>{"Tasks"->React.string}</div>
        <div className={S.sub}>{"Create tasks and manage tests."->React.string}</div>
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
          <div className={S.label}>{"Topic id"->React.string}</div>
          <input className={S.input} value={topicId} onChange={e => setTopicId(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"Title"->React.string}</div>
          <input className={S.input} value={title} onChange={e => setTitle(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"Statement"->React.string}</div>
          <textarea className={S.textarea} value={statement} onChange={e => setStatement(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"Starter code"->React.string}</div>
          <textarea className={S.textarea} value={starterCode} onChange={e => setStarterCode(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.row}>
          <button className={S.smallBtn} disabled={creating} onClick={_ => onCreate()}>
            {(creating ? "Creating..." : "Create")->React.string}
          </button>

          {switch createdId {
           | None => React.null
           | Some(id) =>
             <div className={S.row}>
               <div className={S.badge}>{("Created id: " ++ id)->React.string}</div>
               <NextLink href={"/task/" ++ id} className={S.smallBtn}>{"Open task"->React.string}</NextLink>
             </div>
           }}
        </div>
      </div>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Manage task"->React.string}</div>

      <div className={S.grid}>
        <div className={S.field}>
          <div className={S.label}>{"Task id"->React.string}</div>
          <input className={S.input} value={taskId} onChange={e => setTaskId(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.row}>
          <button className={S.smallBtn} onClick={_ => loadTests(~id=taskId)} disabled={loadingTests}>
            {(loadingTests ? "Loading tests..." : "Reload tests")->React.string}
          </button>
          <button className={S.smallBtn} onClick={_ => onArchive(~id=taskId)} disabled={taskId == ""}>
            {"Archive"->React.string}
          </button>
          <button className={S.smallBtn} onClick={_ => onUnarchive(~id=taskId)} disabled={taskId == ""}>
            {"Unarchive"->React.string}
          </button>
        </div>
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
          <div className={S.label}>{"Name"->React.string}</div>
          <input className={S.input} value={newName} onChange={e => setNewName(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.field}>
          <div className={S.label}>{"Order index"->React.string}</div>
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
        </div>
      </div>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Tests"->React.string}</div>

      <div className={S.sub}>
        {switch (loadingTests, taskId) {
         | (true, _) => "Loading..."->React.string
         | (false, "") => "Set task id to load tests."->React.string
         | (false, _) => ("Count: " ++ tests->Belt.Array.length->Int.toString)->React.string
         }}
      </div>

      <div className={S.list}>
        {tests
         ->Belt.Array.map(t =>
           <div className={S.testRow} key={t.id}>
             <div className={S.left}>
               <div className={S.title}>{(t.name ++ " • " ++ t.id)->React.string}</div>
               <div className={S.meta}>{("input: " ++ stringifyJson(t.input_json))->React.string}</div>
               <div className={S.meta}>{("expected: " ++ stringifyJson(t.expected_json))->React.string}</div>
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
