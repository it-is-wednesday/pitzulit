open Cmdliner

let no_download =
  let doc = "Don't run youtube-dl at all; only parse existing audio and JSON files that were already download in previous runs" in
  Arg.(value & flag & info ["n"; "no-download"] ~doc)

let url =
  let doc = "URL of YouTube video (or any other host supported by youtube-dl)" in
  Arg.(required & pos 0 (some string) None & info [] ~doc)

let youtubedl_path =
  let doc = "Path of youtube-dl executable. Default is trying to get it from PATH" in
  Arg.(value & opt string "youtube-dl" & info ["youtube-dl-path"] ~docv:"PATH" ~doc)

let run main_func =
  let open Cmdliner in
  let doc = "sample text" in
  Term.(exit @@ eval
          (Term.(const main_func $ url $ no_download $ youtubedl_path),
           Term.info "pitzulit" ~version:"v0.1" ~doc))
