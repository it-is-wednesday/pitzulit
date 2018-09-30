open Containers


type song_info =
    { song_title : string
    ; time_seconds : int
    ; length_seconds : int
    }


type video_info =
    { video_title : string
    ; description : string
    ; duration_seconds : int
    ; thumbnail_url : string
    }


let parse_desc desc video_duration : song_info list =
    let open Option.Infix in

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
    in

    let timestamp_pattern      = Re.Perl.compile_pat "(?:\\d+:)?\\d+:\\d+" in
    let list_item_mark_pattern = Re.Perl.compile_pat "\\d+\\." in
    let other_noise_pattern    = Re.Perl.compile_pat "-|–|-|-" in

    let find_timestamp line =
        try
            Re.exec timestamp_pattern line
                |> (fun groups -> Re.Group.get groups 0)
                |> parse_timestamp_string
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


    let infos_without_length = desc
        |> String.lines
        |> List.map begin fun line ->
            match find_timestamp line with
            | None -> None
            | Some time_seconds -> Some (find_title line, time_seconds)
        end
        |> List.keep_some
    in

    List.mapi begin fun i (title, time) ->
        let time_of_next_song =
            let last_elem_index = List.length infos_without_length - 1 in
            if Int.equal i last_elem_index
                then video_duration
                else snd (List.nth infos_without_length (i + 1))
        in
        { song_title = title
        ; time_seconds = time
        ; length_seconds = time_of_next_song - time
        }
    end infos_without_length


let slice_track_from_album ~album_path ~time_begin ~duration ~output_path ~song_title =
    Utils.lwt_shell "ffmpeg -i '%s' -ss '%s' -t '%s' '%s' -y -loglevel warning" 
        album_path 
        (Int.to_string time_begin)
        (Int.to_string duration)
        output_path 


let tag_track ~output_path ~song_title ~artist_name ~album_name ~track_num ~thumbnail_path =
    Utils.lwt_shell "eyeD3 %s --title %s --artist %s --album %s --track %d --add-image %s:FRONT_COVER"
        output_path song_title artist_name album_name track_num thumbnail_path

        
let download_video_and_info url output_file_name : video_info Lwt.t =
    let open Lwt.Infix in
    let create_album_info json =
        let field f =
            List.find (fun pair -> String.equal (fst pair) f) json 
                |> snd
                |> begin function
                    | `String str -> str
                    | `Int n -> Int.to_string n
                    | _ -> failwith (Printf.sprintf "Couldn't find a string/int field named '%s'" f)
                end
        in
        { video_title = field "title"
        ; description = field "description"
        ; thumbnail_url = field "thumbnail"
        ; duration_seconds = field "duration" 
                                |> Int.of_string 
                                |> Option.get_exn
        }
    in

    Lwt_io.printlf "Downloading video at %s..." url >>= fun () ->
    Printf.sprintf "youtube-dl -x --audio-format=mp3 -o '%s' '%s' --print-json" output_file_name url
        |> Lwt_process.shell
        |> Lwt_process.pread 
        >>= fun json_raw -> 
        match Yojson.Safe.from_string json_raw with
        | `Assoc json -> Lwt.return (create_album_info json)
        | _ -> failwith "Weird ass json response from youtube-dl"


let album_artist_and_title video_title =
    let s = String.split_on_char '-' video_title in
    List.nth s 0, List.nth s 1


let () =
    Lwt_main.run begin
        let album_audio_path = "output.mp3" in
        let open Lwt.Infix in
        let url = Sys.argv.(1) in
        let album_info = download_video_and_info url album_audio_path in
        let thumbnail_path = "thumbnail.jpg" in

        let download_thumbnail url dir =
            Lwt_io.printlf "Downloading thumbnail at %s..." url >>= fun () ->
            Utils.lwt_shell "wget --quiet %s -O '%s/%s'" dir url thumbnail_path
        in

        let parse_album album = 
            let output_dir = album.video_title in

            let new_location = Printf.sprintf "%s/%s" output_dir album_audio_path in

            let artist_name, album_name = album_artist_and_title album.video_title in

            Lwt_unix.mkdir output_dir 0o740                           >>= fun () ->
            Lwt_unix.rename album_audio_path new_location             >>= fun () ->
            parse_desc album.description album.duration_seconds
                |> List.mapi (fun i track -> slice_track_from_album
                        ~album_path:album_audio_path
                        ~time_begin:track.time_seconds
                        ~duration:track.length_seconds
                        ~output_path:(Printf.sprintf "%s/%s.mp3" output_dir track.song_title)
                        ~song_title:track.song_title
                        >>= fun () -> tag_track
                        ~output_path:(Printf.sprintf "%s/%s.mp3" output_dir track.song_title)
                        ~song_title:track.song_title
                        ~artist_name
                        ~album_name
                        ~track_num:(i + 1)
                        ~thumbnail_path)
                |> List.cons (download_thumbnail album.thumbnail_url output_dir) 
                |> Lwt.join                                           >>= fun () ->
            Utils.lwt_shell "rm '%s/%s'" output_dir album_audio_path  >>= fun _ ->
            Lwt.return_unit
        in

        album_info >>= parse_album
    end

