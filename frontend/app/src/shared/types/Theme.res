type t = White | Black

let toString = t =>
  switch t {
  | White => "white"
  | Black => "black"
  }

let fromString = s =>
  switch s {
  | "black" => Black
  | _ => White
  }
