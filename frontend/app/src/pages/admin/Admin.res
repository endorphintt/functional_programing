module S = {
  @module("./Admin.module.scss") external page: string = "page"
  @module("./Admin.module.scss") external top: string = "top"
  @module("./Admin.module.scss") external h1: string = "h1"
  @module("./Admin.module.scss") external sub: string = "sub"
  @module("./Admin.module.scss") external grid: string = "grid"
  @module("./Admin.module.scss") external card: string = "card"
  @module("./Admin.module.scss") external cardTitle: string = "cardTitle"
  @module("./Admin.module.scss") external cardSub: string = "cardSub"
  @module("./Admin.module.scss") external cardMeta: string = "cardMeta"
}

@react.component
let make = () => {
  <div className={S.page}>
    <div className={S.top}>
      <div>
        <div className={S.h1}>{"Admin"->React.string}</div>
        <div className={S.sub}>{"Manage content and users."->React.string}</div>
      </div>
    </div>

    <div className={S.grid}>
      <NextLink href="/admin/users" className={S.card}>
        <div className={S.cardTitle}>{"Users"->React.string}</div>
        <div className={S.cardSub}>{"Roles, ratings, accounts."->React.string}</div>
        <div className={S.cardMeta}>{"Soon"->React.string}</div>
      </NextLink>

      <NextLink href="/admin/topics" className={S.card}>
        <div className={S.cardTitle}>{"Topics"->React.string}</div>
        <div className={S.cardSub}>{"Create and edit topics."->React.string}</div>
        <div className={S.cardMeta}>{"Soon"->React.string}</div>
      </NextLink>

      <NextLink href="/admin/tasks" className={S.card}>
        <div className={S.cardTitle}>{"Tasks"->React.string}</div>
        <div className={S.cardSub}>{"Create tasks and tests."->React.string}</div>
        <div className={S.cardMeta}>{"Soon"->React.string}</div>
      </NextLink>

      <NextLink href="/admin/submissions" className={S.card}>
        <div className={S.cardTitle}>{"Submissions"->React.string}</div>
        <div className={S.cardSub}>{"Review and grade."->React.string}</div>
        <div className={S.cardMeta}>{"Soon"->React.string}</div>
      </NextLink>
    </div>
  </div>
}
