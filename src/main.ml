open Containers


let url_to_download =
  match Array.get_safe Sys.argv 1 with
  | Some url -> Lwt.return url
  | None -> Pitzulit_search.interactive_search


let () =
  Lwt_main.run Lwt.Infix.(url_to_download >>= Pitzulit_download.get_album)
