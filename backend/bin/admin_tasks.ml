open Lwt.Infix

let create_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t6 int64 string string string string string) ->! Caqti_type.int64)
    {|
      INSERT INTO tasks (topic_id, title, statement, starter_code, runner, runner_body)
      VALUES (?, ?, ?, ?, ?::task_runner, ?)
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

let get_int64_opt json key =
  let open Yojson.Safe.Util in
  match json |> member key with
  | `Null -> None
  | (`Int i) -> Some (Int64.of_int i)
  | (`Intlit s) -> Int64.of_string_opt s
  | (`String s) -> Int64.of_string_opt s
  | _ -> None

let create _me req =
  Dream.body req >>= fun body ->
  let parsed =
    try Ok (Yojson.Safe.from_string body) with _ -> Error "invalid json"
  in
  match parsed with
  | Error _ ->
      Dream.respond ~status:`Bad_Request "bad json"
  | Ok json ->
      let topic_id = get_int64_opt json "topic_id" in
      let title = get_string_opt json "title" in
      let statement = get_string_opt json "statement" in
      let starter_code =
        match get_string_opt json "starter_code" with
        | Some v -> Some v
        | None -> get_string_opt json "starterCode"
      in
      let runner =
        match get_string_opt json "runner" with
        | Some v -> Some v
        | None -> Some "json"
      in
      let runner_body =
        match get_string_opt json "runner_body" with
        | Some v -> Some v
        | None -> get_string_opt json "runnerBody"
      in
      let runner_body = match runner_body with Some v -> Some v | None -> Some "Solution.solve input" in
      (match topic_id, title, statement, starter_code, runner, runner_body with
       | Some tid, Some t, Some s, Some sc, Some r, Some rb ->
           Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
               Db.find create_request (tid, t, s, sc, r, rb) >>= Caqti_lwt.or_fail
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
