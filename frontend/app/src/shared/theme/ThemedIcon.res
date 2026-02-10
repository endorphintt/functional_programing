@react.component
let make = (~path, ~className=?, ~width=?, ~height=?) => {
  let themeStr = ThemeStore.useThemeStore(s => s["theme"])
  let color = if themeStr == "black" { "white" } else { "black" }

  let w = switch width { | Some(v) => v | None => 15 }
  let h = switch height { | Some(v) => v | None => 15 }

  <NextImage
    src={path ++ "_" ++ color ++ ".svg"}
    width={w}
    height={h}
    alt=""
    className=?className
    priority=true
  />
}
