open Containers

let say, sayf = Util.say, Util.sayf

module Strings = struct
  type ('a) f = ('a, unit, string) format

  let info_json_not_found = {|Couldn't find any file that ends with
.info.json. Does the file exist in this directory? Try running pitzulit
again, without --no-download.|}

  let bins_not_found = {|Couldn't find in PATH one of these binaries: \
youtube-dl, eyeD3, ffmpeg|}

  let youtubedl_cmd : _ f = {|youtube-dl '%s' --extract-audio --audio-format=mp3 \
--output album.mp3 --write-info-json|}

  let eyed3_cmd : _ f = {|eyeD3 '%s' --title '%s' --artist '%s' --album '%s' \
--track %d --add-image %s:FRONT_COVER|}
end


let download url =
  let cmd = Printf.sprintf Strings.youtubedl_cmd url in
  match Sys.command cmd with
  | 0 -> ()
  | error_code ->
    sayf ~err:true "youtube-dl failed with error code %d\n" error_code; exit 1


(** returns: album title, album artist, video description, thumbnail URL *)
let parse_info_json file_name =
  let open Yojson.Basic in
  let json = from_file file_name in
  let noise =
    Re.Perl.compile_pat "(\\[|\\()full album(\\]|\\))" ~opts:[`Caseless]
  in
  let clean = Fun.compose (Re.replace_string noise ~by:"") String.trim in
  let title_parts = json
              |> Util.member "title"
              |> Util.to_string
              |> String.split_on_char '-' in
  let album_artist = List.nth title_parts 0 |> clean in
  let album_title = List.nth title_parts 1 |> clean in
  album_title,
  album_artist,
  Util.to_string (Util.member "description" json),
  Util.to_string (Util.member "thumbnail" json) |> Uri.of_string


let tag file (track: Pitzulit.Track.t) (album: Pitzulit.Album.t) =
  Printf.sprintf Strings.eyed3_cmd
    file track.title album.artist album.title track.track_num album.cover_art
  |> Sys.command


let main url dir no_download no_extract =
  if not (IO.File.exists dir) then begin
    sayf "Directory %s doesn't exist, creating it" dir;
    Unix.mkdir dir 0o777;
  end;

  sayf "Working in %s"
    (if String.equal dir "." then "current directory" else dir);
  Sys.chdir dir;

  (* make sure the required executables are available via PATH *)
  say "Looking for required binaries";
  let required_bins = ["youtube-dl"; "eyeD3"; "ffmpeg"] in
  if not (List.for_all Util.does_exec_exists required_bins) then begin
    say ~err:true Strings.bins_not_found;
    exit 1
  end;

  if no_download then
    say "Skipping video download"
  else
    download url;

  say "Parsing .info.json";
  let album_title, album_artist, desc, cover_uri = parse_info_json "album.mp3.info.json" in

  say "Downloading cover art (video thumbnail)";
  Util.wget cover_uri "cover.jpg" |> Lwt_main.run;

  sayf "Album details found: \"%s\" by %s\n" album_title album_artist;

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
      tag track_file track album |> ignore;)

let () = Cli.run main
