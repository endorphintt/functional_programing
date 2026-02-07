open Lwt.Infix

let get_rating_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->! Caqti_type.int)
    {|
      SELECT rating
      FROM users
      WHERE id = ?
    |}

let me_handler (me : Auth.me) req =
  Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.find get_rating_request me.id >>= Caqti_lwt.or_fail
    )
  >>= fun rating ->
  `Assoc [
    ("id", `String (Int64.to_string me.id));
    ("email", `String me.email);
    ("nickname", `String me.nickname);
    ("role", `String me.role);
    ("rating", `Int rating);
  ]
  |> Yojson.Safe.to_string
  |> Dream.json
