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

let main url no_download dir =
  Sys.chdir dir;

  (* make sure the required executables are available via PATH *)
  let required_bins = ["youtube-dl"; "eyeD3"; "ffmpeg"] in
  if not (List.for_all Util.does_exec_exists required_bins) then begin
    Util.eprint Strings.bins_not_found;
    exit 1
  end;

  if not no_download then download url;

  Yojson.Basic.from_file "album.mp3.info.json"
  |> Yojson.Basic.Util.member "description"
  |> Yojson.Basic.to_string
  |> Desc.parse_tracks_from_desc
  |> List.iter (fun track ->
      Track.extract "album.mp3" track |> ignore)

let () = Cli.run main
