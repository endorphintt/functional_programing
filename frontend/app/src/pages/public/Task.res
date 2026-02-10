module S = {
  @module("./Task.module.scss") external page: string = "page"
  @module("./Task.module.scss") external top: string = "top"
  @module("./Task.module.scss") external h1: string = "h1"
  @module("./Task.module.scss") external sub: string = "sub"
  @module("./Task.module.scss") external actions: string = "actions"
  @module("./Task.module.scss") external btn: string = "btn"
  @module("./Task.module.scss") external card: string = "card"
  @module("./Task.module.scss") external h2: string = "h2"
  @module("./Task.module.scss") external rules: string = "rules"
  @module("./Task.module.scss") external rule: string = "rule"
  @module("./Task.module.scss") external dot: string = "dot"
  @module("./Task.module.scss") external editorWrap: string = "editorWrap"
  @module("./Task.module.scss") external textarea: string = "textarea"
  @module("./Task.module.scss") external row: string = "row"
  @module("./Task.module.scss") external leftRow: string = "leftRow"
  @module("./Task.module.scss") external badge: string = "badge"
}

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

@react.component
let make = (~taskId: string) => {
  let (task, setTask) = React.useState((): option<TasksTypes.task> => None)
  let (code, setCode) = React.useState(() => "")
  let (err, setErr) = React.useState(() => "")
  let (loading, setLoading) = React.useState(() => true)
  let (submitting, setSubmitting) = React.useState(() => false)
  let (lastSubmit, setLastSubmit) = React.useState((): option<TasksTypes.submitResponse> => None)

  React.useEffect1(() => {
    if taskId == "" {
      setLoading(_ => false)
      None
    } else {
      setLoading(_ => true)
      setLastSubmit(_ => None)

      let _ =
        TasksApi.getOne(~id=taskId)
        ->Promise.then(t => {
          setTask(_ => Some(t))
          setCode(_ => t.starter_code)
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

  let onSubmit = () => {
    switch task {
    | None => ()
    | Some(_t) =>
      setSubmitting(_ => true)
      setErr(_ => "")
      setLastSubmit(_ => None)

      let _ =
        TasksApi.submit(~id=taskId, ~code)
        ->Promise.then(r => {
          setLastSubmit(_ => Some(r))
          setSubmitting(_ => false)
          Promise.resolve()
        })
        ->Promise.catch(e => {
          setErr(_ => errMsg(e))
          setSubmitting(_ => false)
          Promise.resolve()
        })
    }
  }

  let topicId =
    switch task {
    | Some(t) => t.topic_id
    | None => ""
    }

  <div className={S.page}>
    <div className={S.top}>
      <div>
        <div className={S.h1}>
          {switch (loading, task) {
           | (true, _) => "Loading..."->React.string
           | (false, Some(t)) => t.title->React.string
           | (false, None) => ("Task " ++ taskId)->React.string
           }}
        </div>
        {switch task {
         | None => React.null
         | Some(t) => <div className={S.sub}>{t.statement->React.string}</div>
         }}
        {switch err {
         | "" => React.null
         | msg => <div className={S.sub}>{("Error: " ++ msg)->React.string}</div>
         }}
      </div>

      <div className={S.actions}>
        <NextLink href={"/topic/" ++ topicId} className={S.btn}>
          {"Back"->React.string}
        </NextLink>

        {if taskId != "" {
            <NextLink href={"/task/" ++ taskId ++ "/submissions"} className={S.btn}>
              {"My submissions"->React.string}
            </NextLink>
          } else {
            React.null
          }}

          {switch lastSubmit {
         | None => React.null
         | Some(r) =>
           <NextLink href={"/submission/" ++ r.submission_id} className={S.btn}>
             {"Open result"->React.string}
           </NextLink>
         }}
      </div>
    </div>

    {switch task {
     | None => React.null
     | Some(_t) =>
       <div className={S.card}>
         <div className={S.h2}>{"What you need to do"->React.string}</div>
         <div className={S.rules}>
           <div className={S.rule}>
             <div className={S.dot} />
             <div>{"Don't change the solve signature or module names"->React.string}</div>
           </div>
           <div className={S.rule}>
             <div className={S.dot} />
             <div>{"Complete the body of solve so that all tests pass"->React.string}</div>
           </div>
           <div className={S.rule}>
             <div className={S.dot} />
             <div>{"Submit and check the result"->React.string}</div>
           </div>
         </div>

         <div className={S.editorWrap}>
           <textarea
             className={S.textarea}
             value={code}
             onChange={e => setCode(_ => ReactEvent.Form.target(e)["value"])}
           />

           <div className={S.row}>
             <div className={S.leftRow}>
               <button className={S.btn} onClick={_ => onSubmit()} disabled={submitting}>
                 {(submitting ? "Submitting..." : "Submit")->React.string}
               </button>

               {switch lastSubmit {
                | None => React.null
                | Some(r) =>
                  <div className={S.badge}>
                    {("score " ++ r.score->Int.toString ++ " | +" ++ r.delta->Int.toString ++ " | rating " ++ r.rating->Int.toString)->React.string}
                  </div>
                }}
             </div>

             {switch lastSubmit {
              | Some(r) => <div className={S.sub}>{("status: " ++ r.status)->React.string}</div>
              | None => React.null
              }}
           </div>
         </div>
       </div>
    }}
  </div>
}
