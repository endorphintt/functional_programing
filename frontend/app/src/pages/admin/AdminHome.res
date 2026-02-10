module S = {
  @module("./AdminHome.module.scss") external page: string = "page"
  @module("./AdminHome.module.scss") external top: string = "top"
  @module("./AdminHome.module.scss") external h1: string = "h1"
  @module("./AdminHome.module.scss") external sub: string = "sub"
  @module("./AdminHome.module.scss") external navCard: string = "navCard"
  @module("./AdminHome.module.scss") external navBtn: string = "navBtn"
  @module("./AdminHome.module.scss") external card: string = "card"
  @module("./AdminHome.module.scss") external h2: string = "h2"
  @module("./AdminHome.module.scss") external list: string = "list"
  @module("./AdminHome.module.scss") external item: string = "item"
  @module("./AdminHome.module.scss") external dot: string = "dot"
}

@react.component
let make = () => {
  <div className={S.page}>
    <div className={S.top}>
      <div>
        <div className={S.h1}>{"Admin"->React.string}</div>
        <div className={S.sub}>{"Manage users, topics, tasks and submissions."->React.string}</div>
      </div>
    </div>

    <div className={S.navCard}>
      <NextLink href="/admin/users" className={S.navBtn}>{"Users"->React.string}</NextLink>
      <NextLink href="/admin/topics" className={S.navBtn}>{"Topics"->React.string}</NextLink>
      <NextLink href="/admin/tasks" className={S.navBtn}>{"Tasks"->React.string}</NextLink>
      <NextLink href="/admin/submissions" className={S.navBtn}>{"Submissions"->React.string}</NextLink>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Next steps"->React.string}</div>

      <div className={S.list}>
        <div className={S.item}><div className={S.dot} /> <div>{"Users: list, change role, inspect profile."->React.string}</div></div>
        <div className={S.item}><div className={S.dot} /> <div>{"Topics: create/edit/delete topics."->React.string}</div></div>
        <div className={S.item}><div className={S.dot} /> <div>{"Tasks: create/edit tasks, publish/unpublish."->React.string}</div></div>
        <div className={S.item}><div className={S.dot} /> <div>{"Submissions: filter by task/user/status, open any submission."->React.string}</div></div>
      </div>
    </div>
  </div>
}
