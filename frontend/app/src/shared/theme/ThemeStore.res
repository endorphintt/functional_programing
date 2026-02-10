type state = {.
  "theme": string,
  "setTheme": string => unit,
  "toggleTheme": unit => unit,
}

@module("./themeStore.js")
external useThemeStore: ((state => 'a)) => 'a = "useThemeStore"
