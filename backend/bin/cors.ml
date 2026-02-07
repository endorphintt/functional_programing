open Lwt.Infix

let add_headers res =
  Dream.set_header res "Access-Control-Allow-Origin" "*";
  Dream.set_header res "Access-Control-Allow-Methods" "GET,POST,PUT,DELETE,OPTIONS";
  Dream.set_header res "Access-Control-Allow-Headers" "authorization,content-type";
  Dream.set_header res "Access-Control-Max-Age" "86400";
  res

let middleware inner req =
  match Dream.method_ req with
  | `OPTIONS ->
      Dream.empty `No_Content >|= fun res -> add_headers res
  | _ ->
      inner req >|= fun res -> add_headers res
