open Containers


type song_info =
    { title : string
    ; timestamp : int * int (* hours, minutes and seconds *)
    }


type album_info =
    { title : string
    ; thumbnail_url : string
    ; duration_seconds : int
    }


let parse_desc desc =
    let timestamp_pattern = Re.Perl.compile_pat "(?:\\d+:)?\\d+:\\d+" in
    let list_item_mark_pattern = Re.Perl.compile_pat "\\d+\\." in
    let other_noise_pattern = Re.Perl.compile_pat "-|–" in
    let open Containers.Option.Infix in

    let parse_timestamp timestamp_string =
        let splits = String.split_on_char ':' timestamp_string in
        Int.of_string (List.nth splits 0) >>= fun minutes ->
        Int.of_string (List.nth splits 1) >>= fun seconds ->
        Option.return (minutes, seconds)
    in

    let find_timestamp line =
        try
            Re.exec timestamp_pattern line
                |> (fun groups -> Re.Group.get groups 0)
                |> parse_timestamp
        with
            Not_found -> None
    in

    let find_title line =
        line
            |> Re.replace_string ~all:false ~by:"" timestamp_pattern
            |> Re.replace_string ~all:false ~by:"" list_item_mark_pattern
            |> Re.replace_string ~all:false ~by:"" other_noise_pattern
            |> String.trim
    in

    let parse_line line =
        match find_timestamp line with
        | Some ts -> Some
            { title = find_title line
            ; timestamp = ts
            }
        | None -> None
    in

    desc
        |> String.lines
        |> List.map parse_line
        |> List.keep_some


let to_seconds time =
    let open Option.Infix in
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


let slice_track album_path time_begin time_end num =
    let open Option.Infix in
    let output = Int.to_string num ^ ".ogg" in
    let length = 
        to_seconds time_end >>= fun e ->
        to_seconds time_begin >>= fun b ->
        Some (e - b) 
    in

    match length with
    | None -> failwith "yeah there's an exception over here"
    | Some length ->
        Printf.sprintf "ffprobe -i %s -ss %s -t %s %s -y" album_path time_begin (Int.to_string length) output
            |> Lwt_process.shell
            |> Lwt_process.exec

        
let download_album_and_fetch_info url output_file_name =
    let open Lwt.Infix in
    let create_album_info json =
        let field f = List.find (fun pair -> String.equal (fst pair) f) json |> snd in

        { title = field "title"
        ; thumbnail_url = field "thumbnail"
        ; duration_seconds = field "duration"
        }
    in
    Printf.sprintf "youtube-dl -x --audio-format=flac -o '%s.%%(ext)s' '%s' --print-json" output_file_name url
        |> Lwt_process.shell
        |> Lwt_process.pread 
        >>= fun json_raw -> 
        match Yojson.Safe.from_string json_raw with
        | `Assoc json -> Lwt.return (create_album_info json)
        | _ -> failwith "Weird ass json response from youtube-dl"


let () =

    Lwt_main.run begin
        Lwt_io.printl "a"
        (*
    let open Lwt.Infix in
    let url = Sys.argv.(1) in
        let desc = fetch_vid_desc url in
        let title = fetch_vid_title url in


        title >>= fun title ->
        desc  >>= fun desc ->
        Lwt_io.printl ("Song title: " ^ title) >>= fun () ->
        parse_desc desc
            |> List.map (fun song ->
                let min, sec = song.timestamp in
                    Printf.sprintf "Epic song: %s @ %d:%d" song.title min sec)
                |> String.concat ",\n"
                |> Lwt_io.printl
                *)
    end

