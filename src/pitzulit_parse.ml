open Containers
open Option.Infix

open Pitzulit_types

let parse_timestamp_string time =
  let hours, minutes, seconds =
    match String.split_on_char ':' time with
    | min::sec::[]     -> "0", min, sec
    | hr::min::sec::[] -> hr, min, sec
    | _                -> "", "", ""
  in
  Int.of_string hours   >>= fun hr ->
  Int.of_string minutes >>= fun min ->
  Int.of_string seconds >>= fun sec ->
  Some (hr * 3600 + min * 60 + sec)
  

let timestamp_pattern      = Re.Perl.compile_pat "(?:\\d+:)?\\d+:\\d+"
let list_item_mark_pattern = Re.Perl.compile_pat "\\d+\\."
let other_noise_pattern    = Re.Perl.compile_pat "-|–|-|-"

let extract_timestamp line =
  try
    Re.exec timestamp_pattern line
    |> (fun groups -> Re.Group.get groups 0)
    |> parse_timestamp_string
  with
    Not_found -> None


let find_title line =
  line
  |> Re.replace_string ~all:false ~by:"" timestamp_pattern
  |> Re.replace_string ~all:false ~by:"" list_item_mark_pattern
  |> Re.replace_string ~all:false ~by:"" other_noise_pattern
  |> String.trim


let infos_without_length desc =
  let extract line =
    match extract_timestamp line with
    | None -> None
    | Some time_seconds -> Some (find_title line, time_seconds)
  in
  desc
  |> String.lines
  |> List.filter_map extract


let track_infos_from_desc desc video_duration : track_info list =
  let infos = infos_without_length desc in
  let append_length index (title, time) =
    let time_of_next_song =
      let last_elem_index = List.length infos - 1 in
      if Int.equal index last_elem_index
      then video_duration
      else snd (List.nth infos (index + 1))
    in
    { song_title = title
    ; time_seconds = time
    ; length_seconds = time_of_next_song - time
    }
  in
  List.mapi append_length infos


let extract_title_data video_title =
  let s = String.split_on_char '-' video_title in
  List.nth s 0, List.nth s 1
