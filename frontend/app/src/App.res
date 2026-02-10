@react.component
let make = (~children) => {
  <>
    <ThemeProvider />
    {children}
  </>
}
