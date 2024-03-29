type t = {
  title: string;
  artist: string;
  cover_art_url: Uri.t;
  tracks: Track.t list;
}

module type InfoParser = sig
  val parse : Yojson.Basic.t -> Track.t list
end

module DescriptionParser : InfoParser = struct
  (* track name patterns *)
  let timestamp_pat        = Re.Perl.compile_pat "(?:\\d+:)?\\d+:\\d+"
  let list_item_mark_pat   = Re.Perl.compile_pat "\\d+\\."
  let other_noise_pat      = Re.Perl.compile_pat "-|–|-|-"

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
      let (let*) = Option.bind in
      let* hr = int_of_string_opt hours in
      let* min = int_of_string_opt minutes in
      let* sec = int_of_string_opt seconds in
      Some (hr * 3600 + min * 60 + sec)
    in

    let extract_timestamp line : int option =
      try
        Re.exec timestamp_pat line
        |> (fun groups -> Re.Group.get groups 0)
        |> parse_timestamp_string
      with
        Not_found -> None
    in

    let extract_title line =
      line
      |> Re.replace_string ~all:false ~by:"" timestamp_pat
      |> Re.replace_string ~all:false ~by:"" list_item_mark_pat
      |> Re.replace_string ~all:false ~by:"" other_noise_pat
      |> String.trim
    in

    Option.bind
      (extract_timestamp raw_line)
      (fun timestamp -> Some {title = extract_title raw_line; timestamp_sec = timestamp})


  let parse info_json =
    let desc =
      Yojson.Basic.Util.(info_json |> member "description" |> to_string) in
    (* gather all lines in given video description to hold a track title and
       timestamp. for example:
       2:30 bruh song
       3:22 second bruh song *)
    let stamp_lines = List.filter_map parse_line (String.split_on_char '\n' desc) in

    (* figure out track's actual time ranges out of the timestamps. we
       take into account the surrounding lines to calculate it. for example,
       given the previous example, we can understand that "bruh song" starts at
       2:30 and ends at 3:22, because the timestamp in the following line is
       3:22. *)
    let num_of_lines = List.length stamp_lines in
    stamp_lines |> List.mapi (fun track_num {title; timestamp_sec} ->
        let time = match track_num with
          (* last track *)
          | x when x = (num_of_lines - 1) -> Track.Time.End timestamp_sec
          (* either the first track or a track in the middle *)
          | _ ->
            (* timestamp at next line *)
            let next_stamp =
              (CCList.get_at_idx_exn (track_num + 1) stamp_lines).timestamp_sec in
            match track_num with
            | 0 -> Track.Time.Beginning next_stamp
            | _ -> Track.Time.Middle (timestamp_sec, next_stamp)
        in
        Track.{title; time; track_num = track_num + 1});;
end

let from_info_json info =
  let open Yojson.Basic in
  let noise = Re.Perl.compile_pat "(\\[|\\()full album(\\]|\\))" ~opts:[`Caseless] in
  let clean = CCFun.compose (Re.replace_string noise ~by:"") String.trim in
  let title_parts = info
                    |> Util.member "title"
                    |> Util.to_string
                    |> String.split_on_char '-' in
  let album_artist = List.nth title_parts 0 |> clean in
  let album_title = List.nth title_parts 1 |> clean in
  { title = album_title
  ; artist = album_artist
  ; cover_art_url = info |> Util.member "thumbnail" |> Util.to_string |> Uri.of_string
  ; tracks = DescriptionParser.parse info }
