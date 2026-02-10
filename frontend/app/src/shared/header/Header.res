module S = {
  @module("./Header.module.scss") external header: string = "header"
  @module("./Header.module.scss") external brand: string = "brand"
  @module("./Header.module.scss") external center: string = "center"
  @module("./Header.module.scss") external nav: string = "nav"
  @module("./Header.module.scss") external navBtn: string = "navBtn"
  @module("./Header.module.scss") external right: string = "right"
  @module("./Header.module.scss") external iconBtn: string = "iconBtn"
  @module("./Header.module.scss") external adminBtn: string = "adminBtn"
  @module("./Header.module.scss") external theme: string = "theme"
  @module("./Header.module.scss") external theme__button: string = "theme__button"
  @module("./Header.module.scss") external moon: string = "moon"
  @module("./Header.module.scss") external sun: string = "sun"
  @module("./Header.module.scss") external current: string = "current"
  @module("./Header.module.scss") external moonIcon: string = "moonIcon"
}

let addListener: (string, 'a => unit) => (unit => unit) =
  %raw(`(name, cb) => { if (typeof window === "undefined") return () => {}; window.addEventListener(name, cb); return () => window.removeEventListener(name, cb); }`)

@react.component
let make = () => {
  let (isAdmin, setIsAdmin) = React.useState(() => Jwt.isAdmin())

  React.useEffect0(() => {
    setIsAdmin(_ => Jwt.isAdmin())
    let cb = _ => setIsAdmin(_ => Jwt.isAdmin())
    let off1 = addListener("auth-changed", cb)
    let off2 = addListener("storage", cb)
    let off3 = addListener("focus", cb)
    Some(() => {
      off1()
      off2()
      off3()
    })
  })

  <header className={S.header}>
    <NextLink href="/" className={S.brand}>
      {"PF"->React.string}
    </NextLink>

    <div className={S.center}>
      <div className={S.nav}>
        <NextLink href="/" className={S.navBtn}>
          {"Topics"->React.string}
        </NextLink>
        <NextLink href="/leaderboard" className={S.navBtn}>
          {"Leaderboard"->React.string}
        </NextLink>
      </div>
    </div>

    <div className={S.right}>
      <NextLink href="/profile" className={S.iconBtn}>
        <ThemedIcon path="/themed_icons/profile" width=20 height=20 />
      </NextLink>

      {if isAdmin {
        <NextLink href="/admin" className={S.adminBtn}>
          {"Admin"->React.string}
        </NextLink>
      } else {
        React.null
      }}

      <ThemeSwitcher />
    </div>
  </header>
}
