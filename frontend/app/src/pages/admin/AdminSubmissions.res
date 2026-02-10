module S = {
  @module("./AdminSubmissions.module.scss") external page: string = "page"
  @module("./AdminSubmissions.module.scss") external top: string = "top"
  @module("./AdminSubmissions.module.scss") external h1: string = "h1"
  @module("./AdminSubmissions.module.scss") external sub: string = "sub"
  @module("./AdminSubmissions.module.scss") external btn: string = "btn"
  @module("./AdminSubmissions.module.scss") external card: string = "card"
  @module("./AdminSubmissions.module.scss") external h2: string = "h2"
  @module("./AdminSubmissions.module.scss") external grid: string = "grid"
  @module("./AdminSubmissions.module.scss") external field: string = "field"
  @module("./AdminSubmissions.module.scss") external label: string = "label"
  @module("./AdminSubmissions.module.scss") external input: string = "input"
  @module("./AdminSubmissions.module.scss") external row: string = "row"
  @module("./AdminSubmissions.module.scss") external smallBtn: string = "smallBtn"
  @module("./AdminSubmissions.module.scss") external pill: string = "pill"
  @module("./AdminSubmissions.module.scss") external error: string = "error"
  @module("./AdminSubmissions.module.scss") external pre: string = "pre"
}

@module("../../shared/auth/AdminGuard.js")
external adminGuard: React.component<unit> = "default"

let errMsg = (e: 'a): string =>
  switch JsExn.message(Obj.magic(e)) {
  | Some(m) => m
  | None => "error"
  }

let jsonStringify: JSON.t => string = %raw("v => globalThis.JSON.stringify(v, null, 2)")
let stringifyJson = (j: JSON.t): string => jsonStringify(Obj.magic(j))

@react.component
let make = () => {
  let (id, setId) = React.useState(() => "")
  let (loading, setLoading) = React.useState(() => false)
  let (err, setErr) = React.useState(() => "")

  let (item, setItem) = React.useState((): option<SubmissionsTypes.submission> => None)

  let load = (~id: string) => {
    if id->String.trim == "" {
      setErr(_ => "Submission id required")
      setItem(_ => None)
    } else {
      setLoading(_ => true)
      setErr(_ => "")
      setItem(_ => None)

      let _ =
        SubmissionsApi.getOne(~id)
        ->Promise.then(s => {
          setItem(_ => Some(s))
          setLoading(_ => false)
          Promise.resolve()
        })
        ->Promise.catch(e => {
          setErr(_ => errMsg(e))
          setLoading(_ => false)
          Promise.resolve()
        })
    }
  }

  <div className={S.page}>
    {React.createElement(adminGuard, ())}

    <div className={S.top}>
      <div>
        <div className={S.h1}>{"Submissions"->React.string}</div>
        <div className={S.sub}>{"Lookup submission by id."->React.string}</div>
      </div>

      <NextLink href="/admin" className={S.btn}>{"Back"->React.string}</NextLink>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Find"->React.string}</div>

      <div className={S.grid}>
        <div className={S.field}>
          <div className={S.label}>{"Submission id"->React.string}</div>
          <input className={S.input} value={id} onChange={e => setId(_ => ReactEvent.Form.target(e)["value"])} />
        </div>

        <div className={S.row}>
          <button className={S.smallBtn} disabled={loading} onClick={_ => load(~id)}>
            {(loading ? "Loading..." : "Load")->React.string}
          </button>
        </div>
      </div>

      {switch err {
       | "" => React.null
       | msg => <div className={S.error}>{("Error: " ++ msg)->React.string}</div>
       }}
    </div>

    {switch item {
     | None => React.null
     | Some(s) =>
       <div className={S.card}>
         <div className={S.h2}>{"Result"->React.string}</div>

         <div className={S.row}>
           <div className={S.pill}>{("status " ++ s.status)->React.string}</div>
           <div className={S.pill}>{("score " ++ s.score->Int.toString)->React.string}</div>
           <div className={S.pill}>
             {("tests " ++ s.passed_tests->Int.toString ++ "/" ++ s.total_tests->Int.toString)->React.string}
           </div>
         </div>

         <div className={S.pre}>{stringifyJson(s.result)->React.string}</div>
       </div>
     }}
  </div>
}
