module S = {
  @module("./Submission.module.scss") external page: string = "page"
  @module("./Submission.module.scss") external h1: string = "h1"
  @module("./Submission.module.scss") external sub: string = "sub"
  @module("./Submission.module.scss") external card: string = "card"
  @module("./Submission.module.scss") external pre: string = "pre"
}

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

@react.component
let make = (~submissionId: string) => {
  let (item, setItem) = React.useState((): option<SubmissionsTypes.submission> => None)
  let (err, setErr) = React.useState(() => "")
  let (loading, setLoading) = React.useState(() => true)

  React.useEffect1(() => {
    if submissionId == "" {
      setLoading(_ => false)
      None
    } else {
      setLoading(_ => true)

      let _ =
        SubmissionsApi.getOne(~id=submissionId)
        ->Promise.then(s => {
          setItem(_ => Some(s))
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
  }, [submissionId])

  <div className={S.page}>
    <div className={S.h1}>
      {switch (loading, item) {
       | (true, _) => "Loading..."->React.string
       | (false, Some(s)) => ("Submission " ++ s.id)->React.string
       | (false, None) => ("Submission " ++ submissionId)->React.string
       }}
    </div>

    {switch err {
     | "" => React.null
     | msg => <div className={S.sub}>{("Error: " ++ msg)->React.string}</div>
     }}

    {switch item {
     | None => React.null
     | Some(s) =>
       <div className={S.card}>
         <div className={S.sub}>
           {("status: " ++ s.status ++ " | score " ++ s.score->Int.toString ++ " | passed " ++ s.passed_tests->Int.toString ++ "/" ++ s.total_tests->Int.toString)->React.string}
         </div>
         <pre className={S.pre}>{JSON.stringify(~space=2, s.result)->React.string}</pre>
       </div>
    }}
  </div>
}
