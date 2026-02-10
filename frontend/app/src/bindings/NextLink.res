@module("./NextLink.js")
@react.component
external make: (
  ~href: string,
  ~className: string=?,
  ~children: React.element,
) => React.element = "default"
