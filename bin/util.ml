open Containers

let sayf ?(err=false) msg =
  let open ANSITerminal in
  let f = if err then printf else eprintf in
  f [magenta; Bold] (msg ^^ "\n")

let say ?(err=false) msg =
  let open ANSITerminal in
  let f = if err then print_string else prerr_string in
  f [magenta; Bold] (msg ^ "\n")

let does_exec_exists name =
  Sys.command (Printf.sprintf "command -v %s 1> /dev/null" name) = 0

let wget uri out_path =
  let open Lwt.Infix in
  Cohttp_lwt_unix.Client.get uri >>= fun (_resp, body) ->
  Cohttp_lwt.Body.to_string body >|= fun body ->
  IO.File.write_exn out_path body
