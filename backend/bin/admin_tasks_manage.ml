open Lwt.Infix

let int_param_opt req key =
  match Dream.query req key with
  | None -> None
  | Some s -> Int64.of_string_opt s

let list_all_request =
  let open Caqti_request.Infix in
  (Caqti_type.unit ->* Caqti_type.(t9 int64 int64 string string string string string string (option string)))
    {|
      SELECT t.id, t.topic_id, t.title, t.statement, t.starter_code,
             t.runner::text, t.runner_body, t.created_at::text, t.archived_at::text
      FROM tasks t
      ORDER BY t.id DESC
    |}

let list_by_topic_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->* Caqti_type.(t9 int64 int64 string string string string string string (option string)))
    {|
      SELECT t.id, t.topic_id, t.title, t.statement, t.starter_code,
             t.runner::text, t.runner_body, t.created_at::text, t.archived_at::text
      FROM tasks t
      WHERE t.topic_id = ?
      ORDER BY t.id DESC
    |}

let get_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->? Caqti_type.(t9 int64 int64 string string string string string string (option string)))
    {|
      SELECT t.id, t.topic_id, t.title, t.statement, t.starter_code,
             t.runner::text, t.runner_body, t.created_at::text, t.archived_at::text
      FROM tasks t
      WHERE t.id = ?
    |}

let row_to_json (id, topic_id, title, statement, starter_code, runner, runner_body, created_at, archived_at) =
  `Assoc [
    ("id", `String (Int64.to_string id));
    ("topic_id", `String (Int64.to_string topic_id));
    ("title", `String title);
    ("statement", `String statement);
    ("starter_code", `String starter_code);
    ("runner", `String runner);
    ("runner_body", `String runner_body);
    ("created_at", `String created_at);
    ("archived_at", (match archived_at with None -> `Null | Some s -> `String s));
  ]

let list _me req =
  let topic_id_opt = int_param_opt req "topic_id" in
  Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
      (match topic_id_opt with
       | None -> Db.collect_list list_all_request ()
       | Some tid -> Db.collect_list list_by_topic_request tid)
      >>= Caqti_lwt.or_fail
    )
  >>= fun rows ->
  rows
  |> List.map row_to_json
  |> fun xs -> Dream.json (Yojson.Safe.to_string (`List xs))

let get_one _me req =
  let id_str = Dream.param req "id" in
  match Int64.of_string_opt id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad id"
  | Some id ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find_opt get_request id >>= Caqti_lwt.or_fail
        )
      >>= function
      | None -> Dream.respond ~status:`Not_Found "not found"
      | Some row ->
          row_to_json row
          |> Yojson.Safe.to_string
          |> Dream.json
