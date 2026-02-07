open Lwt.Infix

let clamp ~min_v ~max_v x =
  if x < min_v then min_v else if x > max_v then max_v else x

let int_param req key default =
  match Dream.query req key with
  | None -> default
  | Some s -> (match int_of_string_opt s with Some v -> v | None -> default)

let list_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t2 int int) ->* Caqti_type.(t4 int64 string string int))
    {|
      SELECT id, email, nickname, rating
      FROM users
      ORDER BY rating DESC, id ASC
      LIMIT ? OFFSET ?
    |}

let leaderboard req =
  let limit = int_param req "limit" 20 |> clamp ~min_v:1 ~max_v:100 in
  let offset = int_param req "offset" 0 |> clamp ~min_v:0 ~max_v:1000000 in
  Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.collect_list list_request (limit, offset) >>= Caqti_lwt.or_fail
    )
  >>= fun rows ->
  let items =
    rows
    |> List.map (fun (id, email, nickname, rating) ->
         `Assoc [
           ("id", `String (Int64.to_string id));
           ("email", `String email);
           ("nickname", `String nickname);
           ("rating", `Int rating);
         ])
  in
  Dream.json (Yojson.Safe.to_string (`Assoc [
    ("limit", `Int limit);
    ("offset", `Int offset);
    ("items", `List items);
  ]))
