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
    let open Yojson.Basic.Util in
    { video_title      = json |> member "title"       |> to_string
    ; description      = json |> member "description" |> to_string
    ; thumbnail_url    = json |> member "thumbnail"   |> to_string
    ; duration_seconds = json |> member "duration"    |> to_int
    }
  in
  Lwt_io.printlf "Downloading video at %s..." url >>= fun () ->
  Printf.sprintf "youtube-dl -x --audio-format=mp3 -o %s %s --print-json" output_file_name url
  |> Lwt_process.shell
  |> Lwt_process.pread 
  >>= Fun.(Yojson.Basic.from_string %> create_album_info %> Lwt.return)


let download_thumbnail url thumbnail_file_name out_dir =
  let open Lwt.Infix in
  Lwt_io.printlf "Downloading thumbnail at %s..." url >>= fun () ->
  Utils.lwt_shell "wget '%s' -O '%s/%s' --quiet" url out_dir thumbnail_file_name


let get_album url =
  let album_audio_file_name = "output.mp3" in
  let open Lwt.Infix in
  let album_info = download_video_and_info url album_audio_file_name in
  let thumbnail_file_name = "thumbnail.jpg" in

  let parse_album (album : video_info) = 
    let output_dir = album.video_title in
    let album_audio_path = Printf.sprintf "%s/%s" output_dir album_audio_file_name in
    let artist_name, album_name = Pitzulit_parse.extract_title_data album.video_title in

    let slice (track : track_info) =
      slice_track_from_album
        ~album_path:(Printf.sprintf "'%s'" album_audio_path)
        ~time_begin:track.time_seconds
        ~duration:track.length_seconds
        ~output_path:(Printf.sprintf "'%s/%s.mp3'" output_dir track.song_title)
      >>= fun () -> Lwt_io.printlf "Extracted \"%s\"" track.song_title
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

    let tracks = Pitzulit_parse.track_infos_from_desc album.description album.duration_seconds in

    let extract_tracks_and_download_thumbnail =
      tracks
      |> List.map slice
      |> List.cons (download_thumbnail album.thumbnail_url thumbnail_file_name output_dir)
      |> Lwt.join                                                              
    in

    let%lwt () =
      if not (Sys.file_exists output_dir)
      then Lwt_unix.mkdir output_dir 0o740
      else Lwt.return_unit
    in
    let%lwt () = Utils.lwt_shell "mv '%s' '%s'" album_audio_file_name album_audio_path    in
    let%lwt () = Lwt_io.printl "Extracting tracks..."                                     in
    let%lwt () = extract_tracks_and_download_thumbnail                                    in
    let%lwt () = Lwt_io.printl "Applying tags..."                                         in
    let%lwt () = tracks |> List.mapi tag |> Lwt.join                                      in
    Utils.lwt_shell "rm '%s'" album_audio_path                               
  in

  album_info >>= parse_album
