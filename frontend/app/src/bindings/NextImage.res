@module("./NextImage.js")
@react.component
external make: (
  ~src: string,
  ~width: int,
  ~height: int,
  ~alt: string,
  ~className: string=?,
  ~priority: bool=?,
) => React.element = "default"
