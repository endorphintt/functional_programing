module S = {
  @module("./AdminUsers.module.scss") external page: string = "page"
  @module("./AdminUsers.module.scss") external top: string = "top"
  @module("./AdminUsers.module.scss") external h1: string = "h1"
  @module("./AdminUsers.module.scss") external sub: string = "sub"
  @module("./AdminUsers.module.scss") external btn: string = "btn"
  @module("./AdminUsers.module.scss") external card: string = "card"
  @module("./AdminUsers.module.scss") external h2: string = "h2"
  @module("./AdminUsers.module.scss") external list: string = "list"
  @module("./AdminUsers.module.scss") external item: string = "item"
  @module("./AdminUsers.module.scss") external dot: string = "dot"
}

@react.component
let make = () => {
  <div className={S.page}>
    <div className={S.top}>
      <div>
        <div className={S.h1}>{"Users"->React.string}</div>
        <div className={S.sub}>{"List users and manage roles."->React.string}</div>
      </div>

      <NextLink href="/admin" className={S.btn}>{"Back"->React.string}</NextLink>
    </div>

    <div className={S.card}>
      <div className={S.h2}>{"Planned"->React.string}</div>

      <div className={S.list}>
        <div className={S.item}><div className={S.dot} /> <div>{"Users list with search and pagination."->React.string}</div></div>
        <div className={S.item}><div className={S.dot} /> <div>{"Change role (user/admin)."->React.string}</div></div>
        <div className={S.item}><div className={S.dot} /> <div>{"Open user profile and submissions."->React.string}</div></div>
      </div>
    </div>
  </div>
}
