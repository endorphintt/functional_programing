open Lwt.Infix

type register_in = {
  email : string;
  password : string;
  nickname : string;
} [@@deriving yojson]

type login_in = {
  email : string;
  password : string;
} [@@deriving yojson]

type me = {
  id : int64;
  role : string;
  email : string;
  nickname : string;
  rating : int;
}

let jwt_secret =
  match Sys.getenv_opt "JWT_SECRET" with
  | Some s -> s
  | None -> "dev_secret_change_me"

let make_token ~user_id ~role ~email ~nickname ~rating =
  let payload =
    [
      ("sub", Int64.to_string user_id);
      ("role", role);
      ("email", email);
      ("nickname", nickname);
      ("rating", string_of_int rating);
    ]
  in
  Jwto.encode Jwto.HS256 jwt_secret payload

let insert_user_request =
  let open Caqti_request.Infix in
  (Caqti_type.(t3 string string string) ->! Caqti_type.(t5 int64 string string string int))
    {|
      INSERT INTO users (email, password_hash, nickname)
      VALUES (?, ?, ?)
      RETURNING id, role::text, email, nickname, rating
    |}

let find_user_by_email_request =
  let open Caqti_request.Infix in
  (Caqti_type.string ->? Caqti_type.(t6 int64 string string string string int))
    {|
      SELECT id, password_hash, role::text, email, nickname, rating
      FROM users
      WHERE email = ?
    |}

let token_json token =
  Dream.json (Yojson.Safe.to_string (`Assoc [ ("token", `String token) ]))

let me_to_json (m : me) =
  `Assoc [
    ("id", `String (Int64.to_string m.id));
    ("role", `String m.role);
    ("email", `String m.email);
    ("nickname", `String m.nickname);
    ("rating", `Int m.rating);
  ]
  |> Yojson.Safe.to_string
  |> Dream.json

let bearer_token req =
  match Dream.header req "authorization" with
  | None -> None
  | Some h ->
      let prefix = "Bearer " in
      if String.length h >= String.length prefix
         && String.sub h 0 (String.length prefix) = prefix
      then Some (String.sub h (String.length prefix) (String.length h - String.length prefix))
      else None

let decode_token token : (me, string) result =
  match Jwto.decode_and_verify jwt_secret token with
  | Error e -> Error e
  | Ok jwt ->
      let payload = Jwto.get_payload jwt in
      let find = Jwto.get_claim in
      match find "sub" payload,
            find "role" payload,
            find "email" payload,
            find "nickname" payload,
            find "rating" payload with
      | Some sub, Some role, Some email, Some nickname, Some rating_s ->
          (match Int64.of_string_opt sub, int_of_string_opt rating_s with
           | Some id, Some rating -> Ok { id; role; email; nickname; rating }
           | _ -> Error "bad token fields")
      | _ ->
          Error "missing token fields"

let require_auth (handler : me -> Dream.request -> Dream.response Lwt.t) : Dream.handler =
  fun req ->
    match bearer_token req with
    | None -> Dream.respond ~status:`Unauthorized "missing token"
    | Some token ->
        match decode_token token with
        | Error _ -> Dream.respond ~status:`Unauthorized "invalid token"
        | Ok m -> handler m req

let require_admin (m : me) (handler : Dream.request -> Dream.response Lwt.t) : Dream.handler =
  fun req ->
    if m.role = "admin" then handler req
    else Dream.respond ~status:`Forbidden "admin only"

let me_handler (m : me) _req =
  me_to_json m

let register req =
  Dream.body req >>= fun body ->
  match Yojson.Safe.from_string body |> register_in_of_yojson with
  | Error _ ->
      Dream.respond ~status:`Bad_Request "bad json"
  | Ok input ->
      let password_hash =
        input.password
        |> Bcrypt.hash
        |> Bcrypt.string_of_hash
      in
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find insert_user_request (input.email, password_hash, input.nickname)
          >>= Caqti_lwt.or_fail
        )
      >>= fun (user_id, role, email, nickname, rating) ->
      match make_token ~user_id ~role ~email ~nickname ~rating with
      | Error _ -> Dream.respond ~status:`Internal_Server_Error "jwt error"
      | Ok token -> token_json token

let login req =
  Dream.body req >>= fun body ->
  match Yojson.Safe.from_string body |> login_in_of_yojson with
  | Error _ ->
      Dream.respond ~status:`Bad_Request "bad json"
  | Ok input ->
      Dream.sql req (fun (module Db : Caqti_lwt.CONNECTION) ->
          Db.find_opt find_user_by_email_request input.email
          >>= Caqti_lwt.or_fail
        )
      >>= function
      | None ->
          Dream.respond ~status:`Unauthorized "invalid credentials"
      | Some (user_id, password_hash, role, email, nickname, rating) ->
          let hash = Bcrypt.hash_of_string password_hash in
          if not (Bcrypt.verify input.password hash) then
            Dream.respond ~status:`Unauthorized "invalid credentials"
          else
            match make_token ~user_id ~role ~email ~nickname ~rating with
            | Error _ -> Dream.respond ~status:`Internal_Server_Error "jwt error"
            | Ok token -> token_json token

let require_admin_auth (handler : me -> Dream.request -> Dream.response Lwt.t) : Dream.handler =
  require_auth (fun m req ->
      require_admin m (fun req2 -> handler m req2) req
    )

let require_user_auth (handler : me -> Dream.request -> Dream.response Lwt.t) : Dream.handler =
  require_auth handler
