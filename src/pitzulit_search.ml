open Containers


type video =
  { title : string
  ; url   : string
  ; index : int
  }


let parse_video_item index item =
  let open Option.Infix in
  let open Soup in

  let graceful_get_exn selector =
    Option.get_lazy
      (fun () ->
        Utils.failwithf "Couldn't find any node of class %s!" selector)
  in

  let yt_uix_tile_link = select_one ".yt-uix-tile-link" item in
  let title = yt_uix_tile_link
              >>= leaf_text
              |> graceful_get_exn ".yt-uix-tile-link"
  in
  let length = select_one ".video-time" item
               >>= leaf_text
               |> graceful_get_exn ".video-time"
  in
  let relative_url = yt_uix_tile_link
                     >>= attribute "href"
                     |> graceful_get_exn ".yt-uix-tile-link"
  in

  { title = Printf.sprintf "%s, length: %s" title length
  ; url = "https://www.youtube.com" ^ relative_url
  ; index = index + 1
  }


let results_in_page page =
  let open Soup in
  parse page
  |> select_one ".item-section"
  |> Option.get_exn
  |> select ".yt-lockup-video"
  |> to_list
  |> List.mapi parse_video_item


let show_videos vids =
  vids
  |> List.map (fun v -> Printf.sprintf "%d. %s" v.index v.title)
  |> String.unlines


let search query =
  let open Cohttp_lwt_unix in
  let open Lwt.Infix in
  query
  |> String.replace ~sub:" " ~by:"+"
  |> Printf.sprintf "https://www.youtube.com/results?search_query=%s"
  |> Uri.of_string
  (* the following param filters out anything that isn't a video (playlists, livestreams, etc.) *)
  |> (fun uri -> Uri.add_query_param' uri ("sp", "EgIQAQ%253D%253D"))
  |> Client.get >>= fun (_, body) ->
  Cohttp_lwt.Body.to_string body
  >>= Fun.(results_in_page %> Lwt.return)


let rec read_number () =
  let%lwt input = Lwt_io.(read_line stdin) in
  match Int.of_string input with
  | Some num -> Lwt.return num
  | None -> read_number ()
  

let interactive_search : string Lwt.t =
  let open Lwt_io in
  let%lwt ()       = print "Aight, let's search for an album! Please enter a query: " in
  let%lwt query    = read_line stdin in
  let%lwt ()       = printlf "Hold up..." in
  let%lwt vids     = search query in
  let%lwt ()       = printf "%sChoose a video: " (show_videos vids) in
  let%lwt vid_num  = read_number () in
  let selected     = List.find (fun v -> v.index = vid_num) vids in
  Lwt.return selected.url
