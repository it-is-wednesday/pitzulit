open Containers


type song_info =
    { title : string
    ; timestamp : int * int (* hours, minutes and seconds *)
    }


let parse_desc desc =
    let timestamp_pattern = Re.Perl.compile_pat "(?:\\d+:)?\\d+:\\d+" in
    let list_item_mark_pattern = Re.Perl.compile_pat "\\d+\\." in
    let open Containers.Option.Infix in

    let parse_timestamp timestamp_string =
        let splits = String.split_on_char ':' timestamp_string in
        Int.of_string (List.nth splits 0) >>= fun minutes ->
        Int.of_string (List.nth splits 1) >>= fun seconds ->
        Option.return (minutes, seconds)
    in

    let find_timestamp line =
        Re.exec timestamp_pattern line
            |> (fun groups -> Re.Group.get groups 0)
            |> parse_timestamp
    in

    let find_title line =
        line
            |> Re.replace_string ~all:false ~by:"" timestamp_pattern
            |> Re.replace_string ~all:false ~by:"" list_item_mark_pattern
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


let fetch_vid_title url =
    Printf.sprintf "youtube-dl -e %s" url
        |> Lwt_process.shell
        |> Lwt_process.pread


let fetch_vid_desc url =
    Printf.sprintf "youtube-dl %s --skip-download --get-description" url
        |> Lwt_process.shell
        |> Lwt_process.pread


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

        
let download_album url output_file_name =
    Printf.sprintf "youtube-dl -x --audio-format=flac -o '%s.%%(ext)s' '%s'" output_file_name url
        |> Lwt_process.shell
        |> Lwt_process.exec


let () =
    let url = Sys.argv.(1) in
    let open Lwt.Infix in

    (*
    let bruh () = 
        Lwt_unix.sleep 2. >>= fun () ->
            parse_desc "1. 3:20 haha\n2. 4:20 yapppp...\n"
                |> List.map (fun song ->
                        let min, sec = song.timestamp in
                        Printf.sprintf "Epic song: %s @ %d:%d" song.title min sec)
                |> String.concat ", "
                |> Lwt.return
    in
    *)

    Lwt_main.run begin
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
    end

