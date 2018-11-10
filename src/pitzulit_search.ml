open Containers


type video =
  { title : string
  ; url   : string
  ; index : int
  }


let parse_video_item index item =
  let open Option.Infix in
  let open Soup in
  let yt_uix_tile_link = select_one ".yt-uix-tile-link" item in
  { title =
      Printf.sprintf "%s, length: %s"
        (yt_uix_tile_link >>= leaf_text |> Option.get_exn) 
        (select_one ".video-time" item >>= leaf_text |> Option.get_exn)
  ; url = "https://www.youtube.com" ^ (yt_uix_tile_link >>= attribute "href" |> Option.get_exn)
  ; index = index + 1
  }


let results_in_page page =
  let open Soup in
  print_endline "results_in_page";
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
  |> (fun uri -> Uri.add_query_param' uri ("sp", "EgIQAQ%253D%253D"))
  |> Client.get >>= fun (_, body) ->
  Cohttp_lwt.Body.to_string body
  >>= Fun.(results_in_page %> Lwt.return)


let rec read_number () =
  let%lwt input = Lwt_io.(read_line stdin) in
  match Int.of_string input with
  | Some num -> Lwt.return num
  | None -> read_number ()
  

let interactive_search () =
  let open Lwt_io in
  let%lwt ()       = print "Aight, let's search for an album! Please enter a query: " in
  let%lwt query    = read_line stdin in
  let%lwt ()       = printlf "Hold up..." in
  let%lwt vids     = search query in
  let%lwt ()       = printf "%sChoose a video: " (show_videos vids) in
  let%lwt vid_num  = read_number () in
  let selected     = List.find (fun v -> v.index = vid_num) vids in
  Lwt.return selected.url
