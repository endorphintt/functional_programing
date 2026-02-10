@react.component
let make = () => {
  let themeStr = ThemeStore.useThemeStore(s => s["theme"])

  React.useEffect1(() => {
    let el = Webapi.Dom.document->Webapi.Dom.Document.documentElement
    Webapi.Dom.Element.setAttribute(el, "data-theme", themeStr)
    None
  }, [themeStr])

  React.null
}
