open Lwt.Infix

let list_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->* Caqti_type.(t5 int64 int64 int string (option string)))
    {|
      SELECT id, topic_id, sort_key, body, code
      FROM topic_paragraphs
      WHERE topic_id = ?
      ORDER BY sort_key ASC, id ASC
    |}

type paragraph_in = {
  sort_key : int;
  body : string;
  code : string option;
} [@@deriving yojson]

type paragraphs_in = paragraph_in list [@@deriving yojson]

let insert_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t4 int64 int string (option string)) ->. Caqti_type.unit)
    {|
      INSERT INTO topic_paragraphs (topic_id, sort_key, body, code)
      VALUES (?, ?, ?, ?)
    |}

let delete_request =
  let open Caqti_request.Infix in
  (Caqti_type.int64 ->. Caqti_type.unit)
    {|
      DELETE FROM topic_paragraphs
      WHERE id = ?
    |}

let list req =
  let topic_id_str = Dream.param req "id" in
  match Int64.of_string_opt topic_id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad topic id"
  | Some topic_id ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.collect_list list_request topic_id >>= Caqti_lwt.or_fail
        )
      >>= fun rows ->
      let items =
        rows
        |> List.map (fun (id, topic_id, sort_key, body, code) ->
             `Assoc [
               ("id", `String (Int64.to_string id));
               ("topic_id", `String (Int64.to_string topic_id));
               ("sort_key", `Int sort_key);
               ("body", `String body);
               ("code", (match code with None -> `Null | Some s -> `String s));
             ])
      in
      Dream.json (Yojson.Safe.to_string (`List items))

let add _me req =
  let topic_id_str = Dream.param req "id" in
  match Int64.of_string_opt topic_id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad topic id"
  | Some topic_id ->
      Dream.body req >>= fun body ->
      match Yojson.Safe.from_string body |> paragraphs_in_of_yojson with
      | Error _ -> Dream.respond ~status:`Bad_Request "bad json"
      | Ok ps ->
          Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
              let rec loop = function
                | [] -> Lwt.return (Ok ())
                | p :: rest ->
                    Db.exec insert_request (topic_id, p.sort_key, p.body, p.code) >>= function
                    | Ok () -> loop rest
                    | Error e -> Lwt.return (Error e)
              in
              loop ps >>= Caqti_lwt.or_fail
            )
          >>= fun () ->
          Dream.json {|{"ok":true}|}

let delete _me req =
  let id_str = Dream.param req "id" in
  match Int64.of_string_opt id_str with
  | None -> Dream.respond ~status:`Bad_Request "bad id"
  | Some pid ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.exec delete_request pid >>= Caqti_lwt.or_fail
        )
      >>= fun () ->
      Dream.json {|{"ok":true}|}
