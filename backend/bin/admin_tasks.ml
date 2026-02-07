open Lwt.Infix

let create_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t3 string string string) ->! Caqti_type.int64)
    {|
      INSERT INTO tasks (title, statement, starter_code)
      VALUES (?, ?, ?)
      RETURNING id
    |}

let archive_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->. Caqti_type.unit)
    {|
      UPDATE tasks
      SET archived_at = now()
      WHERE id = ?
    |}

let unarchive_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->. Caqti_type.unit)
    {|
      UPDATE tasks
      SET archived_at = NULL
      WHERE id = ?
    |}

let get_string_opt json key =
  let open Yojson.Safe.Util in
  match json |> member key with
  | `Null -> None
  | v -> Some (to_string v)

let create _me req =
  Dream.body req >>= fun body ->
  let parsed =
    try Ok (Yojson.Safe.from_string body) with _ -> Error "invalid json"
  in
  match parsed with
  | Error _ ->
      Dream.respond ~status:`Bad_Request "bad json"
  | Ok json ->
      let title = get_string_opt json "title" in
      let statement = get_string_opt json "statement" in
      let starter_code =
        match get_string_opt json "starter_code" with
        | Some v -> Some v
        | None -> get_string_opt json "starterCode"
      in
      (match title, statement, starter_code with
       | Some t, Some s, Some sc ->
           Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
               Db.find create_request (t, s, sc) >>= Caqti_lwt.or_fail
             )
           >>= fun id ->
           Dream.json (Yojson.Safe.to_string (`Assoc [ ("id", `String (Int64.to_string id)) ]))
       | _ ->
           Dream.respond ~status:`Bad_Request "missing fields")

let archive _me req =
  let id_str = Dream.param req "id" in
  match Int64.of_string_opt id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad id"
  | Some id ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.exec archive_request id >>= Caqti_lwt.or_fail
        )
      >>= fun () ->
      Dream.json {|{"ok":true}|}

let unarchive _me req =
  let id_str = Dream.param req "id" in
  match Int64.of_string_opt id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad id"
  | Some id ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.exec unarchive_request id >>= Caqti_lwt.or_fail
        )
      >>= fun () ->
      Dream.json {|{"ok":true}|}
