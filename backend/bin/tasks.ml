open Lwt.Infix

type submit_in = { code : string } [@@deriving yojson]

let list_request =
  let open Caqti_request.Infix in
  (Caqti_type.unit ->* Caqti_type.(t3 int64 string string))
    {|
      SELECT id, title, created_at::text
      FROM tasks
      WHERE archived_at IS NULL
      ORDER BY id DESC
    |}

let get_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->? Caqti_type.(t4 int64 string string string))
    {|
      SELECT id, title, statement, starter_code
      FROM tasks
      WHERE id = ? AND archived_at IS NULL
    |}

let runner_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->? Caqti_type.string)
    {|
      SELECT runner::text
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
    |> List.map (fun (id, title, created_at) ->
         `Assoc [
           ("id", `String (Int64.to_string id));
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
      | Some (id, title, statement, starter_code) ->
          `Assoc [
            ("id", `String (Int64.to_string id));
            ("title", `String title);
            ("statement", `String statement);
            ("starter_code", `String starter_code);
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
  (Caqti_type.int64 ->* Caqti_type.(t4 int64 string string int))
    {|
      SELECT t.id, t.title, t.created_at::text, COALESCE(utb.best_score, 0) AS best_score
      FROM tasks t
      LEFT JOIN user_task_best utb
        ON utb.task_id = t.id AND utb.user_id = ?
      WHERE t.archived_at IS NULL
      ORDER BY t.id DESC
    |}

let my_tasks (me : Auth.me) req =
  Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
      Db.collect_list my_tasks_request me.id >>= Caqti_lwt.or_fail
    )
  >>= fun rows ->
  let items =
    rows
    |> List.map (fun (id, title, created_at, best_score) ->
         `Assoc [
           ("id", `String (Int64.to_string id));
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

let parse_int_json s =
  try
    match Yojson.Safe.from_string s with
    | `Int v -> Ok v
    | _ -> Error "bad"
  with _ -> Error "bad"

let parse_int2_json s =
  try
    match Yojson.Safe.from_string s with
    | `List [ `Int a; `Int b ] -> Ok (a, b)
    | _ -> Error "bad"
  with _ -> Error "bad"

let error_msg_of_runner (e : Runner.run_error) =
  match e with
  | Runner.Timeout -> "timeout"
  | Runner.Runtime_error s -> "runtime_error: " ^ s
  | Runner.Bad_output s -> "bad_output: " ^ s
  | Runner.Compile_error s -> "compile_error: " ^ s

let finalize (module Db : Caqti_lwt.CONNECTION) ~me ~task_id ~code ~status ~score ~passed ~total ~result_json =
  Db.find insert_submission_request (me.Auth.id, task_id, code, status, score, passed, total, result_json)
  >>= Caqti_lwt.or_fail >>= fun submission_id ->
  Db.find_opt best_select_request (me.id, task_id) >>= Caqti_lwt.or_fail >>= fun best_opt ->
  (match best_opt with
   | None ->
       Db.exec best_insert_request (me.id, task_id, score, submission_id)
       >>= fun r -> (match r with Ok () -> Lwt.return (Ok score) | Error e -> Lwt.return (Error e))
   | Some (best_score, _) ->
       if score > best_score then
         Db.exec best_update_request (score, submission_id, me.id, task_id)
         >>= fun r -> (match r with Ok () -> Lwt.return (Ok (score - best_score)) | Error e -> Lwt.return (Error e))
       else
         Lwt.return (Ok 0))
  >>= Caqti_lwt.or_fail >>= fun delta ->
  (if delta > 0 then Db.exec user_add_rating_request (delta, me.id) >>= Caqti_lwt.or_fail else Lwt.return ())
  >>= fun () ->
  Db.find user_get_rating_request me.id >>= Caqti_lwt.or_fail >>= fun rating ->
  Lwt.return (submission_id, delta, rating)

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
              Db.find_opt runner_request task_id >>= Caqti_lwt.or_fail >>= function
              | None ->
                  let result_json = Yojson.Safe.to_string (`Assoc [("error", `String "not found")]) in
                  finalize (module Db) ~me ~task_id ~code:input.code ~status:"error" ~score:0 ~passed:0 ~total:0 ~result_json
                  >|= fun (sid, delta, rating) -> (sid, "error", 0, delta, rating)
              | Some runner ->
                  Db.collect_list tests_request task_id >>= Caqti_lwt.or_fail >>= fun tests ->
                  let total = List.length tests in
                  let base = Filename.get_temp_dir_name () in
                  let temp_dir = Filename.concat base (Printf.sprintf "pf_%Ld_%Ld_%d" me.id task_id (Unix.getpid ())) in

                  (match runner with
                   | "int1" ->
                       Runner.compile_int1_solver ~dir:temp_dir ~code:input.code >>= (function
                         | Error e ->
                             let result_json = Yojson.Safe.to_string (`Assoc [("error", `String (error_msg_of_runner e))]) in
                             finalize (module Db) ~me ~task_id ~code:input.code ~status:"error" ~score:0 ~passed:0 ~total ~result_json
                             >|= fun (sid, delta, rating) -> (sid, "error", 0, delta, rating)
                         | Ok exe ->
                             let rec loop acc passed = function
                               | [] -> Lwt.return (List.rev acc, passed)
                               | (name, input_s, expected_s) :: rest ->
                                   (match parse_int_json input_s, parse_int_json expected_s with
                                    | Ok x, Ok exp ->
                                        Runner.run_exe_int1 ~exe ~x >>= (function
                                          | Ok got ->
                                              let ok = got = exp in
                                              let item =
                                                `Assoc [
                                                  ("name", `String name);
                                                  ("input", `Int x);
                                                  ("expected", `Int exp);
                                                  ("got", `Int got);
                                                  ("ok", `Bool ok);
                                                ]
                                              in
                                              loop (item :: acc) (passed + (if ok then 1 else 0)) rest
                                          | Error err ->
                                              let item =
                                                `Assoc [
                                                  ("name", `String name);
                                                  ("ok", `Bool false);
                                                  ("error", `String (error_msg_of_runner err));
                                                ]
                                              in
                                              loop (item :: acc) passed rest)
                                    | _ ->
                                        let item = `Assoc [("name", `String name); ("ok", `Bool false); ("error", `String "bad test json")] in
                                        loop (item :: acc) passed rest)
                             in
                             loop [] 0 tests >>= fun (items, passed) ->
                             let score = passed in
                             let result_json =
                               `Assoc [("tests", `List items); ("passed", `Int passed); ("total", `Int total)]
                               |> Yojson.Safe.to_string
                             in
                             finalize (module Db) ~me ~task_id ~code:input.code ~status:"done" ~score ~passed ~total ~result_json
                             >|= fun (sid, delta, rating) -> (sid, "done", score, delta, rating))

                   | "int2" ->
                       Runner.compile_int2_solver ~dir:temp_dir ~code:input.code >>= (function
                         | Error e ->
                             let result_json = Yojson.Safe.to_string (`Assoc [("error", `String (error_msg_of_runner e))]) in
                             finalize (module Db) ~me ~task_id ~code:input.code ~status:"error" ~score:0 ~passed:0 ~total ~result_json
                             >|= fun (sid, delta, rating) -> (sid, "error", 0, delta, rating)
                         | Ok exe ->
                             let rec loop acc passed = function
                               | [] -> Lwt.return (List.rev acc, passed)
                               | (name, input_s, expected_s) :: rest ->
                                   (match parse_int2_json input_s, parse_int_json expected_s with
                                    | Ok (a, b), Ok exp ->
                                        Runner.run_exe_int2 ~exe ~a ~b >>= (function
                                          | Ok got ->
                                              let ok = got = exp in
                                              let item =
                                                `Assoc [
                                                  ("name", `String name);
                                                  ("input", `List [ `Int a; `Int b ]);
                                                  ("expected", `Int exp);
                                                  ("got", `Int got);
                                                  ("ok", `Bool ok);
                                                ]
                                              in
                                              loop (item :: acc) (passed + (if ok then 1 else 0)) rest
                                          | Error err ->
                                              let item =
                                                `Assoc [
                                                  ("name", `String name);
                                                  ("ok", `Bool false);
                                                  ("error", `String (error_msg_of_runner err));
                                                ]
                                              in
                                              loop (item :: acc) passed rest)
                                    | _ ->
                                        let item = `Assoc [("name", `String name); ("ok", `Bool false); ("error", `String "bad test json")] in
                                        loop (item :: acc) passed rest)
                             in
                             loop [] 0 tests >>= fun (items, passed) ->
                             let score = passed in
                             let result_json =
                               `Assoc [("tests", `List items); ("passed", `Int passed); ("total", `Int total)]
                               |> Yojson.Safe.to_string
                             in
                             finalize (module Db) ~me ~task_id ~code:input.code ~status:"done" ~score ~passed ~total ~result_json
                             >|= fun (sid, delta, rating) -> (sid, "done", score, delta, rating))

                   | "json" ->
                       Runner.compile_json_solver_body ~dir:temp_dir ~body:input.code >>= (function
                         | Error e ->
                             let result_json = Yojson.Safe.to_string (`Assoc [("error", `String (error_msg_of_runner e))]) in
                             finalize (module Db) ~me ~task_id ~code:input.code ~status:"error" ~score:0 ~passed:0 ~total ~result_json
                             >|= fun (sid, delta, rating) -> (sid, "error", 0, delta, rating)
                         | Ok exe ->
                             let rec loop acc passed = function
                               | [] -> Lwt.return (List.rev acc, passed)
                               | (name, input_s, expected_s) :: rest ->
                                   let expected =
                                     try Ok (Yojson.Safe.from_string expected_s) with _ -> Error ()
                                   in
                                   (match expected with
                                    | Error () ->
                                        let item = `Assoc [("name", `String name); ("ok", `Bool false); ("error", `String "bad expected json")] in
                                        loop (item :: acc) passed rest
                                    | Ok exp ->
                                        Runner.run_exe_json ~exe ~input_json_string:input_s >>= (function
                                          | Error err ->
                                              let item =
                                                `Assoc [
                                                  ("name", `String name);
                                                  ("ok", `Bool false);
                                                  ("error", `String (error_msg_of_runner err));
                                                ]
                                              in
                                              loop (item :: acc) passed rest
                                          | Ok got ->
                                              let ok = got = exp in
                                              let item =
                                                `Assoc [
                                                  ("name", `String name);
                                                  ("input", (try Yojson.Safe.from_string input_s with _ -> `String input_s));
                                                  ("expected", exp);
                                                  ("got", got);
                                                  ("ok", `Bool ok);
                                                ]
                                              in
                                              loop (item :: acc) (passed + (if ok then 1 else 0)) rest))
                             in
                             loop [] 0 tests >>= fun (items, passed) ->
                             let score = passed in
                             let result_json =
                               `Assoc [("tests", `List items); ("passed", `Int passed); ("total", `Int total)]
                               |> Yojson.Safe.to_string
                             in
                             finalize (module Db) ~me ~task_id ~code:input.code ~status:"done" ~score ~passed ~total ~result_json
                             >|= fun (sid, delta, rating) -> (sid, "done", score, delta, rating))

                   | _ ->
                       let result_json = Yojson.Safe.to_string (`Assoc [("error", `String "unknown runner")]) in
                       finalize (module Db) ~me ~task_id ~code:input.code ~status:"error" ~score:0 ~passed:0 ~total ~result_json
                       >|= fun (sid, delta, rating) -> (sid, "error", 0, delta, rating))
            )
          >>= fun (submission_id, status, score, delta, rating) ->
          `Assoc [
            ("submission_id", `String (Int64.to_string submission_id));
            ("status", `String status);
            ("score", `Int score);
            ("delta", `Int delta);
            ("rating", `Int rating);
          ]
          |> Yojson.Safe.to_string
          |> Dream.json
