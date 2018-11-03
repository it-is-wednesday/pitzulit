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

let find_timestamp line =
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


let infos_without_length desc = desc
    |> String.lines
    |> List.map begin fun line ->
        match find_timestamp line with
        | None -> None
        | Some time_seconds -> Some (find_title line, time_seconds)
    end
    |> List.keep_some


let track_infos_from_desc desc video_duration : track_info list =
    let infos = infos_without_length desc in
    List.mapi begin fun i (title, time) ->
        let time_of_next_song =
            let last_elem_index = List.length infos - 1 in
            if Int.equal i last_elem_index
                then video_duration
                else snd (List.nth infos (i + 1))
        in
        { song_title = title
        ; time_seconds = time
        ; length_seconds = time_of_next_song - time
        }
    end infos
