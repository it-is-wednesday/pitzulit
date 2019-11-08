open Containers
module P = Printf

module Strings = struct
  let info_json_not_found = "Couldn't find any file that ends with .info.json. Does the file exist in this directory? Try running pitzulit again, without --no-download."

  let bins_not_found = "Couldn't find in PATH one of these binaries: youtube-dl, eyeD3, ffmpeg"
end

let download url youtubedl_path =
  let cmd = Printf.sprintf "%s %s -x --write-info-json" youtubedl_path url in
  match Sys.command cmd with
  | 0 -> ()
  | error_code -> Printf.eprintf "youtube-dl failed with error code %d\n" error_code; exit 1

(* given a video description, returns the tracklist in it (if any) *)
let parse_tracks_from_desc (desc: string): Track.t list =
  (* gather all lines in given video description to hold a track title and
     timestamp. for example:
     2:30 bruh song
     3:22 second bruh song *)
  let stamp_lines = List.filter_map Desc.parse_line (String.split ~by:"\\n" desc) in

  (* figure out track's actual time ranges out of the timestamps. we
     take into account the surrounding lines to calculate it. for example,
     given the previous example, we can understand that "bruh song" starts at
     2:30 and ends at 3:22, because the timestamp in the following line is 3:22. *)
  let num_of_lines = List.length stamp_lines in
  stamp_lines |> List.mapi (fun line_num Desc.{title; timestamp_sec} ->
      let time = match line_num with
        (* last track *)
        | x when x = (num_of_lines - 1) -> Track.End timestamp_sec
        (* either the first track or a track in the middle *)
        | _ ->
          (* timestamp at next line *)
          let next_stamp = Desc.((List.get_at_idx_exn (line_num + 1) stamp_lines).timestamp_sec) in
          match line_num with
          | 0 -> Track.Beginning next_stamp
          | _ -> Track.Middle (timestamp_sec, next_stamp)
      in
      Track.{title; time})

let main url no_download youtubedl_path =
  (* make sure the required executables are available via PATH *)
  let required_bins = ["youtube-dl"; "eyeD3"; "ffmpeg"] in
  if not (List.for_all Util.does_exec_exists required_bins) then begin
    Util.eprint Strings.bins_not_found;
    exit 1
  end;

  if not no_download then download url youtubedl_path;

  (* youtube-dl, when provided with the --write-info-json flag, prints data
     about the video in JSON format. the data is saved as a file named
     <videotitle>.info.json. since we don't know yet the video's title (because
     we haven't opened the file!), we're looking for any file name that contains
     ".info.json". *)
  Util.find_file_fuzzy ".info.json"
  |> Option.get_lazy (fun _ -> Util.eprint Strings.info_json_not_found; exit 1)
  |> Yojson.Basic.from_file
  |> Yojson.Basic.Util.member "description"
  |> Yojson.Basic.to_string
  |> parse_tracks_from_desc
  |> List.map Track.to_string
  |> List.iter print_endline

let () = Cli.run main
