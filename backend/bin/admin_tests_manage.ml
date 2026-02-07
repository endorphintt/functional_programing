open Lwt.Infix

let list_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->* Caqti_type.(t5 int64 int64 string string string))
    {|
      SELECT id, task_id, name, input_json::text, expected_json::text
      FROM task_tests
      WHERE task_id = ?
      ORDER BY order_index ASC
    |}

let delete_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->. Caqti_type.unit)
    {|
      DELETE FROM task_tests
      WHERE id = ?
    |}

let list _me req =
  let task_id_str = Dream.param req "id" in
  match Int64.of_string_opt task_id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad task id"
  | Some task_id ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.collect_list list_request task_id >>= Caqti_lwt.or_fail
        )
      >>= fun rows ->
      let items =
        rows
        |> List.map (fun (id, task_id, name, input_s, expected_s) ->
             let input_json =
               try Yojson.Safe.from_string input_s with _ -> `String input_s
             in
             let expected_json =
               try Yojson.Safe.from_string expected_s with _ -> `String expected_s
             in
             `Assoc [
               ("id", `String (Int64.to_string id));
               ("task_id", `String (Int64.to_string task_id));
               ("name", `String name);
               ("input_json", input_json);
               ("expected_json", expected_json);
             ])
      in
      Dream.json (Yojson.Safe.to_string (`List items))

let delete _me req =
  let id_str = Dream.param req "test_id" in
  match Int64.of_string_opt id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad test id"
  | Some test_id ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.exec delete_request test_id >>= Caqti_lwt.or_fail
        )
      >>= fun () ->
      Dream.json {|{"ok":true}|}
