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
        { title = find_title line
        ; timestamp = Option.get_exn (find_timestamp line)
        }
    in

    desc
        |> String.lines
        |> List.map parse_line


let fetch_album_title url =
    Printf.sprintf "youtube-dl -e %s" url
        |> Lwt_process.shell
        |> Lwt_process.pread

        
let download_album url output_file_name =
    Printf.sprintf "youtube-dl -x --audio-format=flac -o '%s.%%(ext)s' '%s'" output_file_name url
        |> Lwt_process.shell
        |> Lwt_process.exec


let () =
    let url = Sys.argv.(1) in
    let open Lwt.Infix in

    let bruh () = 
        Lwt.bind (Lwt_unix.sleep 2.) (fun () ->
            parse_desc "1. 3:20 haha\n2. 4:20 yapppp...\n"
                |> List.map (fun song ->
                        let min, sec = song.timestamp in
                        Printf.sprintf "Epic song: %s @ %d:%d" song.title min sec)
                |> String.concat ", "
                |> Lwt.return)
    in

    Lwt_main.run begin
        let shit = bruh () in
        let title = fetch_album_title url in

        shit >>= Lwt_io.printl >>= fun () -> title >>= Lwt_io.print
    end
        (*

        Lwt.bind shit (fun sh ->
            Lwt.bind (Lwt_io.printl sh) (fun () ->
                Lwt.bind title (fun t ->
                    Lwt_io.print t)))
        title 
            >>= Lwt_io.print
            >>= fun () -> shit
            >>= Lwt_io.print
        download_album url "output" >>= fun _ -> print_endline title;
         *)


