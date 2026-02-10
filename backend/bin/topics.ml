open Lwt.Infix

let list_request =
  let open Caqti_request.Infix in
  (Caqti_type.unit ->* Caqti_type.(t4 int64 string string string))
    {|
      SELECT id, title, subtitle, created_at::text
      FROM topics
      WHERE archived_at IS NULL
      ORDER BY id ASC
    |}

let list_admin_request =
  let open Caqti_request.Infix in
  (Caqti_type.unit ->* Caqti_type.(t5 int64 string string string (option string)))
    {|
      SELECT id, title, subtitle, created_at::text, archived_at::text
      FROM topics
      ORDER BY id ASC
    |}

let create_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t2 string string) ->! Caqti_type.int64)
    {|
      INSERT INTO topics (title, subtitle)
      VALUES (?, ?)
      RETURNING id
    |}

let archive_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->. Caqti_type.unit)
    {|
      UPDATE topics
      SET archived_at = now()
      WHERE id = ?
    |}

let unarchive_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->. Caqti_type.unit)
    {|
      UPDATE topics
      SET archived_at = NULL
      WHERE id = ?
    |}

let get_string_opt json key =
  let open Yojson.Safe.Util in
  match json |> member key with
  | `Null -> None
  | v -> Some (to_string v)

let list req =
  Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.collect_list list_request () >>= Caqti_lwt.or_fail
    )
  >>= fun rows ->
  let items =
    rows
    |> List.map (fun (id, title, subtitle, created_at) ->
         `Assoc [
           ("id", `String (Int64.to_string id));
           ("title", `String title);
           ("subtitle", `String subtitle);
           ("created_at", `String created_at);
         ])
  in
  Dream.json (Yojson.Safe.to_string (`List items))

let list_admin _me req =
  Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.collect_list list_admin_request () >>= Caqti_lwt.or_fail
    )
  >>= fun rows ->
  let items =
    rows
    |> List.map (fun (id, title, subtitle, created_at, archived_at) ->
         `Assoc [
           ("id", `String (Int64.to_string id));
           ("title", `String title);
           ("subtitle", `String subtitle);
           ("created_at", `String created_at);
           ("archived_at", (match archived_at with None -> `Null | Some s -> `String s));
         ])
  in
  Dream.json (Yojson.Safe.to_string (`List items))

let create _me req =
  Dream.body req >>= fun body ->
  let parsed =
    try Ok (Yojson.Safe.from_string body) with _ -> Error "invalid json"
  in
  match parsed with
  | Error _ -> Dream.respond ~status:`Bad_Request "bad json"
  | Ok json ->
      let title = get_string_opt json "title" in
      let subtitle = match get_string_opt json "subtitle" with Some s -> Some s | None -> Some "" in
      (match title, subtitle with
       | Some t, Some st ->
           Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
               Db.find create_request (t, st) >>= Caqti_lwt.or_fail
             )
           >>= fun id ->
           Dream.json (Yojson.Safe.to_string (`Assoc [ ("id", `String (Int64.to_string id)) ]))
       | _ ->
           Dream.respond ~status:`Bad_Request "missing fields")

let archive _me req =
  let id_str = Dream.param req "id" in
  match Int64.of_string_opt id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad id"
  | Some tid ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.exec archive_request tid >>= Caqti_lwt.or_fail
        )
      >>= fun () ->
      Dream.json {|{"ok":true}|}

let unarchive _me req =
  let id_str = Dream.param req "id" in
  match Int64.of_string_opt id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad id"
  | Some tid ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.exec unarchive_request tid >>= Caqti_lwt.or_fail
        )
      >>= fun () ->
      Dream.json {|{"ok":true}|}

let topic_get_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->? Caqti_type.(t4 int64 string string (option string)))
    {|
      SELECT id, title, subtitle, archived_at::text
      FROM topics
      WHERE id = ?
    |}

let topic_get_public_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->? Caqti_type.(t3 int64 string string))
    {|
      SELECT id, title, subtitle
      FROM topics
      WHERE id = ? AND archived_at IS NULL
    |}

let paragraphs_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->* Caqti_type.(t4 int64 int string (option string)))
    {|
      SELECT id, sort_key, body, code
      FROM topic_paragraphs
      WHERE topic_id = ?
      ORDER BY sort_key ASC, id ASC
    |}

let tasks_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->* Caqti_type.(t3 int64 string string))
    {|
      SELECT id, title, created_at::text
      FROM tasks
      WHERE topic_id = ? AND archived_at IS NULL
      ORDER BY id DESC
    |}

let page req =
  let topic_id_str = Dream.param req "id" in
  match Int64.of_string_opt topic_id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad topic id"
  | Some topic_id ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find_opt topic_get_public_request topic_id >>= Caqti_lwt.or_fail >>= function
          | None -> Lwt.return_none
          | Some (id, title, subtitle) ->
              Db.collect_list paragraphs_request topic_id >>= Caqti_lwt.or_fail >>= fun ps ->
              Db.collect_list tasks_request topic_id >>= Caqti_lwt.or_fail >>= fun ts ->
              let topic =
                `Assoc [
                  ("id", `String (Int64.to_string id));
                  ("title", `String title);
                  ("subtitle", `String subtitle);
                ]
              in
              let paragraphs =
                ps
                |> List.map (fun (pid, sort_key, body, code) ->
                     `Assoc [
                       ("id", `String (Int64.to_string pid));
                       ("sort_key", `Int sort_key);
                       ("body", `String body);
                       ("code", (match code with None -> `Null | Some s -> `String s));
                     ])
              in
              let tasks =
                ts
                |> List.map (fun (tid, ttitle, created_at) ->
                     `Assoc [
                       ("id", `String (Int64.to_string tid));
                       ("title", `String ttitle);
                       ("created_at", `String created_at);
                     ])
              in
              Lwt.return_some (`Assoc [ ("topic", topic); ("paragraphs", `List paragraphs); ("tasks", `List tasks) ])
        )
      >>= function
      | None -> Dream.respond ~status:`Not_Found "not found"
      | Some json -> Dream.json (Yojson.Safe.to_string json)

let page_admin _me req =
  let topic_id_str = Dream.param req "id" in
  match Int64.of_string_opt topic_id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad topic id"
  | Some topic_id ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find_opt topic_get_request topic_id >>= Caqti_lwt.or_fail >>= function
          | None -> Lwt.return_none
          | Some (id, title, subtitle, archived_at) ->
              Db.collect_list paragraphs_request topic_id >>= Caqti_lwt.or_fail >>= fun ps ->
              Db.collect_list tasks_request topic_id >>= Caqti_lwt.or_fail >>= fun ts ->
              let topic =
                `Assoc [
                  ("id", `String (Int64.to_string id));
                  ("title", `String title);
                  ("subtitle", `String subtitle);
                  ("archived_at", (match archived_at with None -> `Null | Some s -> `String s));
                ]
              in
              let paragraphs =
                ps
                |> List.map (fun (pid, sort_key, body, code) ->
                     `Assoc [
                       ("id", `String (Int64.to_string pid));
                       ("sort_key", `Int sort_key);
                       ("body", `String body);
                       ("code", (match code with None -> `Null | Some s -> `String s));
                     ])
              in
              let tasks =
                ts
                |> List.map (fun (tid, ttitle, created_at) ->
                     `Assoc [
                       ("id", `String (Int64.to_string tid));
                       ("title", `String ttitle);
                       ("created_at", `String created_at);
                     ])
              in
              Lwt.return_some (`Assoc [ ("topic", topic); ("paragraphs", `List paragraphs); ("tasks", `List tasks) ])
        )
      >>= function
      | None -> Dream.respond ~status:`Not_Found "not found"
      | Some json -> Dream.json (Yojson.Safe.to_string json)
