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


let tag file (track: Pitzulit.Track.t) (album: Pitzulit.Album.t) cover_file =
  Printf.sprintf Strings.eyed3_cmd
    file track.title album.artist album.title track.track_num cover_file
  |> Sys.command


let main url dir no_download no_extract =
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

  let album =
    Yojson.Basic.from_file "album.mp3.info.json"
    |> Pitzulit.Album.from_info_json
  in

  let dir =
    if String.equal dir "[named after album title]" then album.title else dir in

  if not (IO.File.exists dir) then begin
    sayf "Creating directory %s" dir;
    Unix.mkdir dir 0o777;
  end;

  say "Downloading cover art (video thumbnail)";
  let cover_file = dir ^ "/cover.jpg" in
  Util.wget album.cover_art_url cover_file |> Lwt_main.run;

  album.tracks
  |> List.iter (fun (track : Pitzulit.Track.t) ->
      let track_file = Printf.sprintf "%s/%s.mp3" dir track.title in
      say track_file;
      if not no_extract then
        Pitzulit.Track.extract "album.mp3" dir track;
      tag track_file track album cover_file |> ignore;)

let () = Cli.run main
