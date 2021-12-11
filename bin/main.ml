(** Print [msg] to stderr with a newline *)
let err msg =
  let out = Printf.eprintf (msg ^^ "\n") in
  flush stderr;
  out


(** Return true [name] is a command in PATH *)
let is_command_absent name =
  Sys.command (Printf.sprintf "command -v %s 1> /dev/null" name) != 0


(** make sure the required executables are available via PATH *)
let check_binaries =
  let bins = ["youtube-dl"; "eyeD3"; "ffmpeg"] in
  let not_found = List.filter is_command_absent bins in
  not_found |> List.iter (fun bin -> err "%s not in path" bin);
  if (List.length not_found) > 0 then exit 1


let main url dir no_download no_extract verbose =
  let (let*) = Result.bind in
  let* album, cover_file, dir = Pitzulit.Main.setup ~url ~dir ~no_download in

  (* extract and tag all tracks in album *)
  print_endline "Extraction started!";
  let tracks_amount = List.length album.tracks in
  album.tracks
  |> List.iter (fun t ->
      (match Pitzulit.Main.handle_track t
               ~artist:album.artist ~album:album.title ~dir ~cover_file ~no_extract ~verbose with
      | Ok () -> ()
      | Error error ->
        (match error with
         | `Eyed3Error code -> Printf.eprintf "eyeD3 failed with error code %d\n" code
         | `FfmpegError code -> Printf.eprintf "ffmpeg failed with error code %d\n" code);
        flush stderr;
        exit 1);
      Printf.printf "Created %s (%d/%d)\n" t.title t.track_num tracks_amount; flush stdout);

  Ok ()

let () =
  check_binaries;
  Cli.run main
