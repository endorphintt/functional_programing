open Lwt.Infix

type test_in = {
  name : string;
  input_json : Yojson.Safe.t;
  expected_json : Yojson.Safe.t;
  order_index : int;
} [@@deriving yojson]

type tests_in = test_in list [@@deriving yojson]

let insert_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t5 int64 string string string int) ->. Caqti_type.unit)
    {|
      INSERT INTO task_tests (task_id, name, input_json, expected_json, order_index)
      VALUES (?, ?, ?::jsonb, ?::jsonb, ?)
    |}

let add _me req =
  let task_id_str = Dream.param req "id" in
  match Int64.of_string_opt task_id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad task id"
  | Some task_id ->
      Dream.body req >>= fun body ->
      match Yojson.Safe.from_string body |> tests_in_of_yojson with
      | Error _ -> Dream.respond ~status:`Bad_Request "bad json"
      | Ok tests ->
          Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
              let rec loop = function
                | [] -> Lwt.return (Ok ())
                | t :: rest ->
                    let input_s = Yojson.Safe.to_string t.input_json in
                    let expected_s = Yojson.Safe.to_string t.expected_json in
                    Db.exec insert_request (task_id, t.name, input_s, expected_s, t.order_index)
                    >>= fun r ->
                    match r with
                    | Ok () -> loop rest
                    | Error e -> Lwt.return (Error e)
              in
              loop tests >>= Caqti_lwt.or_fail
            )
          >>= fun () ->
          Dream.json {|{"ok":true}|}
