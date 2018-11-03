open Containers

open Pitzulit_types

let slice_track_from_album ~album_path ~time_begin ~duration ~output_path =
    Utils.lwt_shell "ffmpeg -i %s -ss %s -t %s %s -y -loglevel warning 1> /dev/null" 
        album_path 
        (Int.to_string time_begin)
        (Int.to_string duration)
        output_path 


let tag_track ~output_path ~song_title ~artist_name ~album_name ~track_num ~thumbnail_path =
    Utils.lwt_shell "eyeD3 %s --title %s --artist %s --album %s --track %d --add-image %s:FRONT_COVER 1> /dev/null"
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
    Printf.sprintf "youtube-dl -x --audio-format=mp3 -o %s %s --print-json" output_file_name url
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
        let album_audio_file_name = "output.mp3" in
        let open Lwt.Infix in
        let url = Sys.argv.(1) in
        let album_info = download_video_and_info url album_audio_file_name in
        let thumbnail_file_name = "thumbnail.jpg" in

        let parse_album album = 
            let output_dir = album.video_title in

            let album_audio_path =
                Printf.sprintf "%s/%s" output_dir album_audio_file_name 
            in

            let artist_name, album_name = album_artist_and_title album.video_title in

            let slice track =
                Lwt.finalize
                    (fun () -> slice_track_from_album
                        ~album_path:(Printf.sprintf "'%s'" album_audio_path)
                        ~time_begin:track.time_seconds
                        ~duration:track.length_seconds
                        ~output_path:(Printf.sprintf "'%s/%s.mp3'" output_dir track.song_title))
                    (fun () ->
                        Lwt_io.printlf "Extracted \"%s\"" track.song_title)
            in

            let tag track_num track =
                tag_track
                    ~output_path:(Printf.sprintf "'%s/%s.mp3'" output_dir track.song_title)
                    ~song_title:(Printf.sprintf "'%s'" track.song_title)
                    ~artist_name:(Printf.sprintf "'%s'" artist_name)
                    ~album_name:(Printf.sprintf "'%s'" album_name)
                    ~track_num:(track_num + 1)
                    ~thumbnail_path:(Printf.sprintf "'%s/%s'" output_dir thumbnail_file_name)
            in

            let download_thumbnail =
                let url = album.thumbnail_url in
                Lwt_io.printlf "Downloading thumbnail at %s..." url >>= fun () ->
                Utils.lwt_shell "wget '%s' -O '%s/%s' --quiet" url output_dir thumbnail_file_name
            in

            let tracks = Parse_desc.track_infos_from_desc album.description album.duration_seconds in

            Lwt_unix.mkdir output_dir 0o740                                          >>= fun () ->
            Utils.lwt_shell "mv '%s' '%s'" album_audio_file_name album_audio_path    >>= fun () ->
            Lwt_io.printl "Extracting tracks..."                                     >>= fun () ->
            tracks |> List.map slice |> List.cons download_thumbnail |> Lwt.join     >>= fun () ->
            Lwt_io.printl "Applying tags..."                                         >>= fun () ->
            tracks |> List.mapi tag |> Lwt.join                                      >>= fun () ->
            Utils.lwt_shell "rm '%s'" album_audio_path
        in

        album_info >>= parse_album
    end

