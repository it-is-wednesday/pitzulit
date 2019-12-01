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

let eyeD3 file ~title ~artist ~album ~track_num ~cover : unit Lwt.t =
  ("eyeD3", [|"eyeD3"; file; "--title"; title; "--artist"; artist;
             "--album"; album; "--track"; Int.to_string track_num;
             "--add-image"; cover ^ ":FRONT_COVER"|])
  |> Lwt_process.exec ~stdout:`Dev_null
  |> Lwt.map (fun _ -> ())

let youtube_dl url =
  let cmd =
    Printf.sprintf
      "youtube-dl '%s' --extract-audio --audio-format=mp3 \
       --output album.mp3 --write-info-json" url
  in
  match Sys.command cmd with
  | 0 -> ()
  | error_code ->
    sayf ~err:true "youtube-dl failed with error code %d\n" error_code; exit 1
