(** Pretty print [msg] to stderr with a newline *)
let err msg =
  let open ANSITerminal in
  eprintf [magenta; Bold] (msg ^^ "\n")


(** Return true [name] is a command in PATH *)
let is_command_absent name =
  Sys.command (Printf.sprintf "command -v %s 1> /dev/null" name) != 0


(** Download thing at [uri] and save as a file in [out_path] *)
let wget uri out_path =
  let open Lwt.Infix in
  Cohttp_lwt_unix.Client.get uri >>= fun (_resp, body) ->
  Cohttp_lwt.Body.to_string body >|= fun body ->
  CCIO.File.write_exn out_path body


(** tag [file] with eyeD3 *)
let eyeD3 file ~title ~artist ~album ~track_num ~cover =
  Printf.sprintf
    "eyeD3 '%s' --title '%s' --artist '%s' --album '%s' \
     --track %d --add-image %s:FRONT_COVER"
    file title artist album track_num cover
  |> Sys.command


(** Download audio of youtube video at [url], saves it into album.mp3 at current directory *)
let youtube_dl url =
  let cmd =
    Printf.sprintf
      "youtube-dl '%s' --extract-audio --audio-format=mp3 \
       --output album.mp3 --write-info-json" url
  in
  match Sys.command cmd with
  | 0 -> ()
  | error_code ->
    err "youtube-dl failed with error code %d" error_code; exit 1


(** make sure the required executables are available via PATH *)
let check_binaries =
  let bins = ["youtube-dl"; "eyeD3"; "ffmpeg"] in
  let not_found = List.filter is_command_absent bins in
  not_found |> List.iter (fun bin -> err "%s not in path" bin; exit 1)


let main url dir no_download no_extract =
  check_binaries;
  if not no_download then youtube_dl url;

  let album = Yojson.Basic.from_file "album.mp3.info.json" |> Pitzulit.Album.from_info_json in
  let dir = if String.equal dir "[named after album title]" then album.title else dir in

  (* create target directory if doesn't exist *)
  if not (CCIO.File.exists dir) then Unix.mkdir dir 0o777;

  (* Download cover art (video thumbnail) *)
  let cover_file = dir ^ "/cover.jpg" in
  wget album.cover_art_url cover_file |> Lwt_main.run;

  (* extract and tag all tracks in album *)
  album.tracks
  |> List.iter (fun (track : Pitzulit.Track.t) ->
      let track_file = Printf.sprintf "%s/%s.mp3" dir track.title in
      if not no_extract then begin
        let exit_code = Pitzulit.Track.extract "album.mp3" dir track in
        if Int.equal exit_code 255 then exit 1
      end;

      eyeD3 track_file
        ~title:track.title
        ~artist:album.artist
        ~album:album.title
        ~track_num:track.track_num
        ~cover:cover_file |> ignore)

let () = Cli.run main
