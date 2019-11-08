open Containers
open Option.Infix

let timestamp_pattern      = Re.Perl.compile_pat "(?:\\d+:)?\\d+:\\d+"
let list_item_mark_pattern = Re.Perl.compile_pat "\\d+\\."
let other_noise_pattern    = Re.Perl.compile_pat "-|–|-|-"

type stamp_line = {
  title: string;
  timestamp_sec: int
}

let parse_line (raw_line: string) : stamp_line option =
  let parse_timestamp_string time : int option =
    (* "0:02:01" -> 121 *)
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
  in

  let extract_timestamp line : int option =
    try
      Re.exec timestamp_pattern line
      |> (fun groups -> Re.Group.get groups 0)
      |> parse_timestamp_string
    with
      Not_found -> None
  in

  let extract_title line =
    line
    |> Re.replace_string ~all:false ~by:"" timestamp_pattern
    |> Re.replace_string ~all:false ~by:"" list_item_mark_pattern
    |> Re.replace_string ~all:false ~by:"" other_noise_pattern
    |> String.trim
  in

  let open Option.Infix in
  extract_timestamp raw_line >>= fun timestamp ->
  Some {title = extract_title raw_line;
        timestamp_sec = timestamp}


let extract_title_data video_title =
  let s = String.split_on_char '-' video_title in
  List.nth s 0, List.nth s 1
