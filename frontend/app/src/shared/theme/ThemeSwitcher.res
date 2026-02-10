@module("./ThemeSwitcher.module.scss")
external styles: {.
  "theme": string,
  "theme__button": string,
  "moon": string,
  "sun": string,
  "current": string,
  "moonIcon": string,
} = "default"

let cx = (a: string, b: string) => a ++ " " ++ b

@react.component
let make = () => {
  let themeStr = ThemeStore.useThemeStore(s => s["theme"])
  let setTheme = ThemeStore.useThemeStore(s => s["setTheme"])

  let moonClass =
    if themeStr == "black" {
      cx(cx(styles["theme__button"], styles["moon"]), styles["current"])
    } else {
      cx(styles["theme__button"], styles["moon"])
    }

  let sunClass =
    if themeStr == "white" {
      cx(cx(styles["theme__button"], styles["sun"]), styles["current"])
    } else {
      cx(styles["theme__button"], styles["sun"])
    }

  <div className={styles["theme"]}>
    <button onClick={_ => setTheme("black")} className={moonClass} type_="button">
      <NextImage
        src="/themed_icons/moon.svg"
        width={15}
        height={15}
        alt="moon"
        priority=true
        className={styles["moonIcon"]}
      />
    </button>

    <button onClick={_ => setTheme("white")} className={sunClass} type_="button">
      <ThemedIcon path="/themed_icons/sun" />
    </button>
  </div>
}
