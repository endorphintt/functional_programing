open Lwt.Infix

type run_error =
  | Compile_error of string
  | Runtime_error of string
  | Timeout
  | Bad_output of string

let write_file path content =
  Lwt_io.with_file ~mode:Lwt_io.Output path (fun oc -> Lwt_io.write oc content)

let ensure_dir dir =
  Lwt.catch
    (fun () -> Lwt_unix.mkdir dir 0o755)
    (function
      | Unix.Unix_error (Unix.EEXIST, _, _) -> Lwt.return_unit
      | e -> Lwt.fail e)

let run_full ?timeout (prog, argv) =
  let p = Lwt_process.open_process_full (prog, argv) in
  let read_out = Lwt_io.read p#stdout
  and read_err = Lwt_io.read p#stderr in
  let wait = p#status in
  let all =
    read_out >>= fun out ->
    read_err >>= fun err ->
    wait >>= fun st ->
    Lwt.return (out, err, st)
  in
  match timeout with
  | None -> all
  | Some sec ->
      Lwt.catch
        (fun () -> Lwt_unix.with_timeout sec (fun () -> all))
        (function
          | Lwt_unix.Timeout ->
              (try p#terminate with _ -> ());
              Lwt.return ("", "", Unix.WEXITED 124)
          | e -> Lwt.fail e)

let run_full_with_stdin ?timeout (prog, argv) stdin_s =
  let p = Lwt_process.open_process_full (prog, argv) in
  let write_in =
    Lwt_io.write p#stdin stdin_s >>= fun () ->
    Lwt_io.close p#stdin
  in
  let read_out = Lwt_io.read p#stdout
  and read_err = Lwt_io.read p#stderr in
  let wait = p#status in
  let all =
    write_in >>= fun () ->
    read_out >>= fun out ->
    read_err >>= fun err ->
    wait >>= fun st ->
    Lwt.return (out, err, st)
  in
  match timeout with
  | None -> all
  | Some sec ->
      Lwt.catch
        (fun () -> Lwt_unix.with_timeout sec (fun () -> all))
        (function
          | Lwt_unix.Timeout ->
              (try p#terminate with _ -> ());
              Lwt.return ("", "", Unix.WEXITED 124)
          | e -> Lwt.fail e)

let compile_common ~dir ~code ~main =
  let user_ml = Filename.concat dir "user.ml" in
  let main_ml = Filename.concat dir "main.ml" in
  let exe = Filename.concat dir "run.exe" in
  ensure_dir dir >>= fun () ->
  write_file user_ml (code ^ "\n") >>= fun () ->
  write_file main_ml main >>= fun () ->
  let step1 =
    ("ocamlfind",
     [| "ocamlfind"; "ocamlopt"; "-package"; "yojson"; "-linkpkg"; "-O2"; "-c"; "-I"; dir
      ; "-o"; Filename.concat dir "user.cmx"
      ; user_ml
     |])
  in
  run_full ~timeout:10.0 step1 >>= fun (_o1, e1, st1) ->
  match st1 with
  | Unix.WEXITED 0 ->
      let step2 =
        ("ocamlfind",
         [| "ocamlfind"; "ocamlopt"; "-package"; "yojson"; "-linkpkg"; "-O2"; "-I"; dir
          ; "-o"; exe
          ; Filename.concat dir "user.cmx"
          ; main_ml
         |])
      in
      run_full ~timeout:10.0 step2 >>= fun (_o2, e2, st2) ->
      (match st2 with
       | Unix.WEXITED 0 -> Lwt.return (Ok exe)
       | _ -> Lwt.return (Error (Compile_error e2)))
  | _ ->
      Lwt.return (Error (Compile_error e1))

let compile_json_solver ~dir ~code =
  let main =
{|open Yojson.Safe

let () =
  let s = In_channel.input_all stdin in
  let input = Yojson.Safe.from_string s in
  let output = User.solve input in
  Out_channel.output_string stdout (Yojson.Safe.to_string output)
|}
  in
  compile_common ~dir ~code ~main

let run_exe_json ~exe ~input_json_string =
  let cmd = (exe, [| exe |]) in
  run_full_with_stdin ~timeout:1.5 cmd input_json_string >>= fun (out, err, st) ->
  match st with
  | Unix.WEXITED 0 ->
      (try
         let j = Yojson.Safe.from_string out in
         Lwt.return (Ok j)
       with _ ->
         Lwt.return (Error (Bad_output out)))
  | Unix.WEXITED 124 -> Lwt.return (Error Timeout)
  | _ -> Lwt.return (Error (Runtime_error err))
