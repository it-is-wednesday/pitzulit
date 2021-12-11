type error = [
  (* int is the error code *)
  | `YoutubeDlError of int
  | `FfmpegError of int
  | `Eyed3Error of int
]

(** Download thing at [uri] and save as a file in [out_path] *)
let wget uri out_path =
  let open Lwt.Infix in
  Cohttp_lwt_unix.Client.get uri >>= fun (_resp, body) ->
  Cohttp_lwt.Body.to_string body >|= fun body ->
  CCIO.File.write_exn out_path body


(** tag [file] with eyeD3 *)
let eyeD3 file ~title ~artist ~album ~track_num ~cover ~verbose =
  (* eyed3 had a twisted idea of a quiet mode!! I wanted it to only print errors, but --quiet
     only cuts half of the input, so I had to take matters into my own hands. and pipe
     stdout to devnull. *)
  let devnull_redirect = if verbose then "" else "1> /dev/null" in
  let exit_code = Printf.sprintf
      "eyeD3 '%s' --title '%s' --artist '%s' --album '%s' \
       --track %d --add-image %s:FRONT_COVER %s"
      file title artist album track_num cover devnull_redirect
                  |> Sys.command
  in
  match exit_code with
  | 0 -> Ok ()
  | code -> Error (`Eyed3Error code)


(** Download audio of youtube video at [url], saves it into album.mp3 at current directory *)
let youtube_dl url =
  let cmd =
    Printf.sprintf
      "youtube-dl '%s' --extract-audio --audio-format=mp3 \
       --output album.mp3 --write-info-json" url
  in
  match Sys.command cmd with
  | 0 -> Ok ()
  | error_code -> Error (`YoutubeDlError error_code)


let setup ~url ~dir ~no_download =
  let (let*) = Result.bind in
  let* _ = if not no_download then youtube_dl url else Ok () in

  let album = Yojson.Basic.from_file "album.mp3.info.json" |> Album.from_info_json in
  let dir = if String.equal dir "[named after album title]" then album.title else dir in

  (* create target directory if doesn't exist *)
  if not (CCIO.File.exists dir) then Unix.mkdir dir 0o777;

  (* Download cover art (video thumbnail) *)
  let cover_file = dir ^ "/cover.jpg" in
  wget album.cover_art_url cover_file |> Lwt_main.run;
  Ok (album, cover_file, dir)


let handle_track (track: Track.t) ~artist ~album ~dir ~cover_file ~no_extract ~verbose =
  let track_file = Printf.sprintf "%s/%s.mp3" dir track.title in
  let (let*) = Result.bind in
  let* _ = if not no_extract
    then Track.extract "album.mp3" dir track verbose
    else Ok ()
  in
  eyeD3 track_file
    ~title:track.title
    ~artist
    ~album
    ~track_num:track.track_num
    ~cover:cover_file
    ~verbose
