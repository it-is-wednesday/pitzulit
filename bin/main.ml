open Containers

module P = Printf

module Strings = struct
  let info_json_not_found = "Couldn't find any file that ends with .info.json. Does the file exist in this directory? Try running pitzulit again, without --no-download."

  let bins_not_found = "Couldn't find in PATH one of these binaries: youtube-dl, eyeD3, ffmpeg"
end

let download url =
  let cmd = Printf.sprintf "youtube-dl '%s' --extract-audio --audio-format=mp3 --output album.mp3 --write-info-json" url in
  match Sys.command cmd with
  | 0 -> ()
  | error_code -> Printf.eprintf "youtube-dl failed with error code %d\n" error_code; exit 1


let parse_info_json file_name =
  let open Yojson.Basic in
  let json = from_file file_name in
  Util.to_string (Util.member "title" json),
  Util.to_string (Util.member "description" json),
  Util.to_string (Util.member "thumbnail" json) |> Uri.of_string


let tag file (track: Pitzulit.Track.t) (album: Pitzulit.Album.t) =
  Printf.sprintf "eyeD3 '%s' --title '%s' --artist '%s' --album '%s' --track %d --add-image %s:FRONT_COVER"
    file track.title album.artist album.title track.track_num album.cover_art
  |> Sys.command


let main url dir no_download no_extract =
  if not (IO.File.exists dir) then begin
    Printf.printf "Directory %s doesn't exist, creating it" dir;
    Unix.mkdir dir 0o777;
  end;
  Printf.printf "Working in %s" (if String.equal dir "." then "current directory" else dir);
  Sys.chdir dir;

  print_endline "Looking for required binaries";
  (* make sure the required executables are available via PATH *)
  let required_bins = ["youtube-dl"; "eyeD3"; "ffmpeg"] in
  if not (List.for_all Util.does_exec_exists required_bins) then begin
    Util.eprint Strings.bins_not_found;
    exit 1
  end;

  if no_download then
    print_endline "Skipping video download"
  else
    download url;

  print_endline "Parsing .info.json";
  let video_title, desc, cover_uri = parse_info_json "album.mp3.info.json" in

  print_endline "Downloading cover art (video thumbnail)";
  Util.wget cover_uri "cover.jpg" |> Lwt_main.run;

  let album_artist, album_title = Pitzulit.Desc.extract_title_data video_title in
  (* Printf.printf "Album details found: \"%s\" by %s\n" album_title album_artist; *)

  let album = Pitzulit.Album.{
      title = album_title;
      artist = album_artist;
      cover_art = IO.File.make "cover.jpg" } in

  desc
  |> Pitzulit.Desc.parse_tracks_from_desc
  |> List.iter (fun (track : Pitzulit.Track.t) ->
      let track_file = track.title ^ ".mp3" in
      if not no_extract then
        Pitzulit.Track.extract "album.mp3" track;
      tag track_file track album |> ignore;
    )

let () = Cli.run main
