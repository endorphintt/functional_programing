open Lwt.Infix

let get_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t2 int64 int64) ->? Caqti_type.(t6 int64 string int int int string))
    {|
      SELECT id, status, score, passed_tests, total_tests, result_json::text
      FROM user_task_answers
      WHERE id = ? AND user_id = ?
    |}

let get_one (me : Auth.me) req =
  let id_str = Dream.param req "id" in
  match Int64.of_string_opt id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad id"
  | Some sub_id ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find_opt get_request (sub_id, me.id) >>= Caqti_lwt.or_fail
        )
      >>= function
      | None -> Dream.respond ~status:`Not_Found "not found"
      | Some (id, status, score, passed, total, result_s) ->
          let result_json =
            try Yojson.Safe.from_string result_s with _ -> `String result_s
          in
          `Assoc [
            ("id", `String (Int64.to_string id));
            ("status", `String status);
            ("score", `Int score);
            ("passed_tests", `Int passed);
            ("total_tests", `Int total);
            ("result", result_json);
          ]
          |> Yojson.Safe.to_string
          |> Dream.json
