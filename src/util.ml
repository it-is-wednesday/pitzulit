open Containers

let find_file_fuzzy pattern =
  let pattern = String.Find.compile pattern in
  Sys.readdir "."
  |> Array.find_map
    (fun s ->
       if Int.(String.Find.find ~pattern s <> -1) then Some s
       else None)

let eprint msg =
  IO.write_line stderr msg

let does_exec_exists name =
  Sys.command (Printf.sprintf "command -v %s 1> /dev/null" name) = 0

let wget uri out_path =
  let open Lwt.Infix in
  Cohttp_lwt_unix.Client.get uri >>= fun (_resp, body) ->
  Cohttp_lwt.Body.to_string body >|= fun body ->
  IO.File.write_exn out_path body
