open Lwt.Infix

type submit_in = { code : string } [@@deriving yojson]

let list_request =
  let open Caqti_request.Infix in
  (Caqti_type.unit ->* Caqti_type.(t4 int64 int64 string string))
    {|
      SELECT t.id, t.topic_id, t.title, t.created_at::text
      FROM tasks t
      JOIN topics tp ON tp.id = t.topic_id
      WHERE t.archived_at IS NULL AND tp.archived_at IS NULL
      ORDER BY t.id DESC
    |}

let list_by_topic_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->* Caqti_type.(t4 int64 int64 string string))
    {|
      SELECT t.id, t.topic_id, t.title, t.created_at::text
      FROM tasks t
      JOIN topics tp ON tp.id = t.topic_id
      WHERE t.archived_at IS NULL AND t.topic_id = ? AND tp.archived_at IS NULL
      ORDER BY t.id DESC
    |}

let get_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->? Caqti_type.(t7 int64 int64 string string string string string))
    {|
      SELECT id, topic_id, title, statement, starter_code, runner::text, runner_body
      FROM tasks
      WHERE id = ? AND archived_at IS NULL
    |}

let tests_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->* Caqti_type.(t3 string string string))
    {|
      SELECT name, input_json::text, expected_json::text
      FROM task_tests
      WHERE task_id = ?
      ORDER BY order_index ASC
    |}

let insert_submission_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t8 int64 int64 string string int int int string) ->! Caqti_type.int64)
    {|
      INSERT INTO user_task_answers (user_id, task_id, code, status, score, passed_tests, total_tests, result_json)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?::jsonb)
      RETURNING id
    |}

let best_select_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t2 int64 int64) ->? Caqti_type.(t2 int int64))
    {|
      SELECT best_score, best_submission_id
      FROM user_task_best
      WHERE user_id = ? AND task_id = ?
    |}

let best_insert_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t4 int64 int64 int int64) ->. Caqti_type.unit)
    {|
      INSERT INTO user_task_best (user_id, task_id, best_score, best_submission_id, updated_at)
      VALUES (?, ?, ?, ?, now())
    |}

let best_update_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t4 int int64 int64 int64) ->. Caqti_type.unit)
    {|
      UPDATE user_task_best
      SET best_score = ?, best_submission_id = ?, updated_at = now()
      WHERE user_id = ? AND task_id = ?
    |}

let user_add_rating_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t2 int int64) ->. Caqti_type.unit)
    {|
      UPDATE users
      SET rating = rating + ?
      WHERE id = ?
    |}

let user_get_rating_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->! Caqti_type.int)
    {|
      SELECT rating
      FROM users
      WHERE id = ?
    |}

let clamp ~min_v ~max_v x =
  if x < min_v then min_v else if x > max_v then max_v else x

let int_param req key default =
  match Dream.query req key with
  | None -> default
  | Some s -> (match int_of_string_opt s with Some v -> v | None -> default)

let list req =
  Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.collect_list list_request () >>= Caqti_lwt.or_fail
    )
  >>= fun rows ->
  let items =
    rows
    |> List.map (fun (id, topic_id, title, created_at) ->
         `Assoc [
           ("id", `String (Int64.to_string id));
           ("topic_id", `String (Int64.to_string topic_id));
           ("title", `String title);
           ("created_at", `String created_at);
         ])
  in
  Dream.json (Yojson.Safe.to_string (`List items))

let list_by_topic req =
  let topic_id_str = Dream.param req "id" in
  match Int64.of_string_opt topic_id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad topic id"
  | Some topic_id ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.collect_list list_by_topic_request topic_id >>= Caqti_lwt.or_fail
        )
      >>= fun rows ->
      let items =
        rows
        |> List.map (fun (id, topic_id, title, created_at) ->
             `Assoc [
               ("id", `String (Int64.to_string id));
               ("topic_id", `String (Int64.to_string topic_id));
               ("title", `String title);
               ("created_at", `String created_at);
             ])
      in
      Dream.json (Yojson.Safe.to_string (`List items))

let show req =
  let id_str = Dream.param req "id" in
  match Int64.of_string_opt id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad id"
  | Some id ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find_opt get_request id >>= Caqti_lwt.or_fail
        )
      >>= function
      | None -> Dream.respond ~status:`Not_Found "not found"
      | Some (id, topic_id, title, statement, starter_code, runner, runner_body) ->
          `Assoc [
            ("id", `String (Int64.to_string id));
            ("topic_id", `String (Int64.to_string topic_id));
            ("title", `String title);
            ("statement", `String statement);
            ("starter_code", `String starter_code);
            ("runner", `String runner);
            ("runner_body", `String runner_body);
          ]
          |> Yojson.Safe.to_string
          |> Dream.json

let my_best_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t2 int64 int64) ->? Caqti_type.int)
    {|
      SELECT best_score
      FROM user_task_best
      WHERE user_id = ? AND task_id = ?
    |}

let my_best (me : Auth.me) req =
  let task_id_str = Dream.param req "id" in
  match Int64.of_string_opt task_id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad task id"
  | Some task_id ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find_opt my_best_request (me.id, task_id) >>= Caqti_lwt.or_fail
        )
      >>= function
      | None -> Dream.json {|{"best_score":0}|}
      | Some s -> Dream.json (Yojson.Safe.to_string (`Assoc [ ("best_score", `Int s) ]))

let my_tasks_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->* Caqti_type.(t5 int64 int64 string string int))
    {|
      SELECT t.id, t.topic_id, t.title, t.created_at::text, COALESCE(utb.best_score, 0) AS best_score
      FROM tasks t
      JOIN topics tp ON tp.id = t.topic_id
      LEFT JOIN user_task_best utb
        ON utb.task_id = t.id AND utb.user_id = ?
      WHERE t.archived_at IS NULL AND tp.archived_at IS NULL
      ORDER BY t.id DESC
    |}

let my_tasks (me : Auth.me) req =
  Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.collect_list my_tasks_request me.id >>= Caqti_lwt.or_fail
    )
  >>= fun rows ->
  let items =
    rows
    |> List.map (fun (id, topic_id, title, created_at, best_score) ->
         `Assoc [
           ("id", `String (Int64.to_string id));
           ("topic_id", `String (Int64.to_string topic_id));
           ("title", `String title);
           ("created_at", `String created_at);
           ("best_score", `Int best_score);
         ])
  in
  Dream.json (Yojson.Safe.to_string (`List items))

let my_submissions_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t4 int64 int64 int int) ->* Caqti_type.(t6 int64 string int int int string))
    {|
      SELECT id, status, score, passed_tests, total_tests, created_at::text
      FROM user_task_answers
      WHERE user_id = ? AND task_id = ?
      ORDER BY id DESC
      LIMIT ? OFFSET ?
    |}

let my_submissions (me : Auth.me) req =
  let task_id_str = Dream.param req "id" in
  match Int64.of_string_opt task_id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad task id"
  | Some task_id ->
      let limit = int_param req "limit" 20 |> clamp ~min_v:1 ~max_v:100 in
      let offset = int_param req "offset" 0 |> clamp ~min_v:0 ~max_v:1000000 in
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.collect_list my_submissions_request (me.id, task_id, limit, offset)
          >>= Caqti_lwt.or_fail
        )
      >>= fun rows ->
      let items =
        rows
        |> List.map (fun (id, status, score, passed, total, created_at) ->
             `Assoc [
               ("id", `String (Int64.to_string id));
               ("status", `String status);
               ("score", `Int score);
               ("passed_tests", `Int passed);
               ("total_tests", `Int total);
               ("created_at", `String created_at);
             ])
      in
      Dream.json (Yojson.Safe.to_string (`Assoc [
        ("limit", `Int limit);
        ("offset", `Int offset);
        ("items", `List items);
      ]))

let submit (me : Auth.me) req =
  let task_id_str = Dream.param req "id" in
  match Int64.of_string_opt task_id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad task id"
  | Some task_id ->
      Dream.body req >>= fun body ->
      match Yojson.Safe.from_string body |> submit_in_of_yojson with
      | Error _ -> Dream.respond ~status:`Bad_Request "bad json"
      | Ok input ->
          Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
              Db.collect_list tests_request task_id >>= Caqti_lwt.or_fail >>= fun tests ->
              let total = List.length tests in
              let temp_dir =
                let base = Filename.get_temp_dir_name () in
                Filename.concat base (Printf.sprintf "pf_%Ld_%Ld_%d" me.id task_id (Unix.getpid ()))
              in
              Db.find_opt get_request task_id >>= Caqti_lwt.or_fail >>= function
              | None ->
                  Db.find user_get_rating_request me.id >>= Caqti_lwt.or_fail >>= fun rating ->
                  Lwt.return (-1L, 0, 0, rating, "error")
              | Some (_id, _topic_id, _title, _statement, _starter, runner, runner_body) ->
                  let code =
                    if runner = "json" then
                      "module Solution = struct\n" ^ input.code ^ "\nend\n"
                      ^ "open Yojson.Safe\n"
                      ^ "let solve input = (" ^ runner_body ^ ")\n"
                    else
                      input.code
                  in
                  Runner.compile_json_solver ~dir:temp_dir ~code >>= function
                  | Error (Runner.Compile_error err) ->
                      let result_json =
                        `Assoc [ ("compile_error", `String err) ]
                        |> Yojson.Safe.to_string
                      in
                      Db.find insert_submission_request (me.id, task_id, input.code, "error", 0, 0, total, result_json)
                      >>= Caqti_lwt.or_fail
                      >>= fun submission_id ->
                      Db.find user_get_rating_request me.id >>= Caqti_lwt.or_fail >>= fun rating ->
                      Lwt.return (submission_id, 0, 0, rating, "error")
                  | Error Runner.Timeout ->
                      let result_json =
                        `Assoc [ ("error", `String "timeout") ]
                        |> Yojson.Safe.to_string
                      in
                      Db.find insert_submission_request (me.id, task_id, input.code, "error", 0, 0, total, result_json)
                      >>= Caqti_lwt.or_fail
                      >>= fun submission_id ->
                      Db.find user_get_rating_request me.id >>= Caqti_lwt.or_fail >>= fun rating ->
                      Lwt.return (submission_id, 0, 0, rating, "error")
                  | Error (Runner.Runtime_error err) ->
                      let result_json =
                        `Assoc [ ("runtime_error", `String err) ]
                        |> Yojson.Safe.to_string
                      in
                      Db.find insert_submission_request (me.id, task_id, input.code, "error", 0, 0, total, result_json)
                      >>= Caqti_lwt.or_fail
                      >>= fun submission_id ->
                      Db.find user_get_rating_request me.id >>= Caqti_lwt.or_fail >>= fun rating ->
                      Lwt.return (submission_id, 0, 0, rating, "error")
                  | Error (Runner.Bad_output out) ->
                      let result_json =
                        `Assoc [ ("bad_output", `String out) ]
                        |> Yojson.Safe.to_string
                      in
                      Db.find insert_submission_request (me.id, task_id, input.code, "error", 0, 0, total, result_json)
                      >>= Caqti_lwt.or_fail
                      >>= fun submission_id ->
                      Db.find user_get_rating_request me.id >>= Caqti_lwt.or_fail >>= fun rating ->
                      Lwt.return (submission_id, 0, 0, rating, "error")
                  | Ok exe ->
                      let rec normalize = function
                        | `Assoc kvs ->
                            `Assoc (kvs |> List.map (fun (k, v) -> (k, normalize v)) |> List.sort (fun (a, _) (b, _) -> compare a b))
                        | `List xs -> `List (List.map normalize xs)
                        | x -> x
                      in
                      let parse_json s =
                        try Ok (Yojson.Safe.from_string s) with _ -> Error "bad json"
                      in
                      let rec run_tests acc passed = function
                        | [] -> Lwt.return (List.rev acc, passed)
                        | (name, input_s, expected_s) :: rest ->
                            (match parse_json input_s, parse_json expected_s with
                             | Ok inp, Ok exp ->
                                 Runner.run_exe_json ~exe ~input_json_string:input_s >>= (function
                                   | Ok got ->
                                       let ok = normalize got = normalize exp in
                                       let item =
                                         `Assoc [
                                           ("name", `String name);
                                           ("input", inp);
                                           ("expected", exp);
                                           ("got", got);
                                           ("ok", `Bool ok);
                                         ]
                                       in
                                       run_tests (item :: acc) (passed + (if ok then 1 else 0)) rest
                                   | Error Runner.Timeout ->
                                       let item =
                                         `Assoc [
                                           ("name", `String name);
                                           ("input_raw", `String input_s);
                                           ("ok", `Bool false);
                                           ("error", `String "timeout");
                                         ]
                                       in
                                       run_tests (item :: acc) passed rest
                                   | Error (Runner.Runtime_error e) ->
                                       let item =
                                         `Assoc [
                                           ("name", `String name);
                                           ("input_raw", `String input_s);
                                           ("ok", `Bool false);
                                           ("error", `String ("runtime: " ^ e));
                                         ]
                                       in
                                       run_tests (item :: acc) passed rest
                                   | Error (Runner.Bad_output o) ->
                                       let item =
                                         `Assoc [
                                           ("name", `String name);
                                           ("input_raw", `String input_s);
                                           ("ok", `Bool false);
                                           ("error", `String ("bad_output: " ^ o));
                                         ]
                                       in
                                       run_tests (item :: acc) passed rest
                                   | Error (Runner.Compile_error _) ->
                                       let item =
                                         `Assoc [
                                           ("name", `String name);
                                           ("ok", `Bool false);
                                           ("error", `String "compile_error_unexpected");
                                         ]
                                       in
                                       run_tests (item :: acc) passed rest)
                             | _ ->
                                 let item =
                                   `Assoc [
                                     ("name", `String name);
                                     ("ok", `Bool false);
                                     ("error", `String "bad test json");
                                     ("input_raw", `String input_s);
                                     ("expected_raw", `String expected_s);
                                   ]
                                 in
                                 run_tests (item :: acc) passed rest)
                      in
                      run_tests [] 0 tests >>= fun (items, passed) ->
                      let score = passed in
                      let result_json =
                        `Assoc [
                          ("tests", `List items);
                          ("passed", `Int passed);
                          ("total", `Int total);
                        ]
                        |> Yojson.Safe.to_string
                      in
                      Db.find insert_submission_request (me.id, task_id, input.code, "done", score, passed, total, result_json)
                      >>= Caqti_lwt.or_fail
                      >>= fun submission_id ->
                      Db.find_opt best_select_request (me.id, task_id) >>= Caqti_lwt.or_fail >>= fun best_opt ->
                      (match best_opt with
                       | None ->
                           Db.exec best_insert_request (me.id, task_id, score, submission_id)
                           >>= fun r -> (match r with Ok () -> Lwt.return (Ok score) | Error e -> Lwt.return (Error e))
                       | Some (best_score, _best_sub) ->
                           if score > best_score then
                             Db.exec best_update_request (score, submission_id, me.id, task_id)
                             >>= fun r -> (match r with Ok () -> Lwt.return (Ok (score - best_score)) | Error e -> Lwt.return (Error e))
                           else
                             Lwt.return (Ok 0))
                      >>= Caqti_lwt.or_fail
                      >>= fun delta ->
                      (if delta > 0 then Db.exec user_add_rating_request (delta, me.id) >>= Caqti_lwt.or_fail else Lwt.return ())
                      >>= fun () ->
                      Db.find user_get_rating_request me.id >>= Caqti_lwt.or_fail >>= fun rating ->
                      Lwt.return (submission_id, score, delta, rating, "done")
            )
          >>= fun (submission_id, score, delta, rating, status) ->
          `Assoc [
            ("submission_id", `String (Int64.to_string submission_id));
            ("status", `String status);
            ("score", `Int score);
            ("delta", `Int delta);
            ("rating", `Int rating);
          ]
          |> Yojson.Safe.to_string
          |> Dream.json
