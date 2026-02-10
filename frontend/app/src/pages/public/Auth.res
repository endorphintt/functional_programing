@module("./Auth.module.scss")
external s: {.
  "wrap": string,
  "card": string,
  "titleRow": string,
  "title": string,
  "form": string,
  "input": string,
  "button": string,
  "linkRow": string,
  "linkBtn": string,
  "error": string,
} = "default"

type mode = Login | Register

let redirect: string => unit = %raw(`(path) => { window.location.href = path; return undefined; }`)

@react.component
let make = () => {
  let (mode, setMode) = React.useState(() => Login)
  let (email, setEmail) = React.useState(() => "")
  let (password, setPassword) = React.useState(() => "")
  let (nickname, setNickname) = React.useState(() => "")
  let (loading, setLoading) = React.useState(() => false)
  let (err, setErr) = React.useState(() => "")

  let title =
    switch mode {
    | Login => "Login"
    | Register => "Register"
    }

  let submit = _ => {
    setErr(_ => "")
    setLoading(_ => true)

    let p =
      switch mode {
      | Login => AuthApi.login({email, password})
      | Register => AuthApi.register({email, password, nickname})
      }

    p
    ->Promise.then(r => {
      Token.setToken(r.token)
      redirect("/")
      Promise.resolve(())
    })
    ->Promise.catch(_ => {
      setErr(_ => "Auth failed")
      Promise.resolve(())
    })
    ->Promise.finally(() => {
      setLoading(_ => false)
    })
    ->ignore
  }

  let switchMode = _ =>
    switch mode {
    | Login => setMode(_ => Register)
    | Register => setMode(_ => Login)
    }

  <div className={s["wrap"]}>
    <div className={s["card"]}>
      <div className={s["titleRow"]}>
        <div className={s["title"]}>{title->React.string}</div>
        <ThemeSwitcher />
      </div>

      {err != "" ? <div className={s["error"]}>{err->React.string}</div> : React.null}

      <div className={s["form"]}>
        <input
          className={s["input"]}
          value={email}
          placeholder="email"
          onChange={e => setEmail(_ => ReactEvent.Form.target(e)["value"])}
        />

        {switch mode {
         | Register =>
             <input
               className={s["input"]}
               value={nickname}
               placeholder="nickname"
               onChange={e => setNickname(_ => ReactEvent.Form.target(e)["value"])}
             />
         | Login => React.null
         }}

        <input
          className={s["input"]}
          value={password}
          type_="password"
          placeholder="password"
          onChange={e => setPassword(_ => ReactEvent.Form.target(e)["value"])}
        />

        <button
          className={s["button"]}
          onClick={submit}
          disabled={loading}
          type_="button">
          {(if loading { "..." } else { title })->React.string}
        </button>
      </div>

      <div className={s["linkRow"]}>
        {switch mode {
         | Login => "Don't have account?"->React.string
         | Register => "Have already account?"->React.string
         }}
        <button className={s["linkBtn"]} onClick={switchMode} type_="button">
          {(switch mode { | Login => "Register" | Register => "Login" })->React.string}
        </button>
      </div>
    </div>
  </div>
}
