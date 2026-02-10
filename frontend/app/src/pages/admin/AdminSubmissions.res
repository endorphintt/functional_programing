module S = {
  @module("./AdminSubmissions.module.scss") external page: string = "page"
  @module("./AdminSubmissions.module.scss") external top: string = "top"
  @module("./AdminSubmissions.module.scss") external h1: string = "h1"
  @module("./AdminSubmissions.module.scss") external sub: string = "sub"
  @module("./AdminSubmissions.module.scss") external btn: string = "btn"
  @module("./AdminSubmissions.module.scss") external card: string = "card"
  @module("./AdminSubmissions.module.scss") external h2: string = "h2"
  @module("./AdminSubmissions.module.scss") external list: string = "list"
  @module("./AdminSubmissions.module.scss") external item: string = "item"
  @module("./AdminSubmissions.module.scss") external dot: string = "dot"
}

@react.component
let make = () => {
  <div className={S.page}>
    <div className={S.top}>
      <div>
        <div className={S.h1}>{"Submissions"->React.string}</div>
        <div className={S.sub}>{"Search and inspect submissions."->React.string}</div>
      </div>

      <NextLink href="/admin" className={S.btn}>{"Back"->React.string}</NextLink>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Planned"->React.string}</div>

      <div className={S.list}>
        <div className={S.item}><div className={S.dot} /> <div>{"Filter by task/user/status."->React.string}</div></div>
        <div className={S.item}><div className={S.dot} /> <div>{"Open any submission by id."->React.string}</div></div>
        <div className={S.item}><div className={S.dot} /> <div>{"Moderation tools if needed."->React.string}</div></div>
      </div>
    </div>
  </div>
}
