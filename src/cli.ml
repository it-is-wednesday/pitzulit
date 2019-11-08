open Cmdliner

let no_download =
  let doc = "Don't run youtube-dl at all; only parse existing audio and JSON files that were already download in previous runs" in
  Arg.(value & flag & info ["n"; "no-download"] ~doc)

let url =
  let doc = "URL of YouTube video (or any other host supported by youtube-dl)" in
  Arg.(required & pos 0 (some string) None & info [] ~doc)

let dir =
  let doc = "Directory in which all the fun will happen" in
  Arg.(value & opt string "." & info ["d"; "dir"] ~docv:"PATH" ~doc)

let run main_func =
  let open Cmdliner in
  let doc = "sample text" in
  Term.(exit @@ eval
          (Term.(const main_func $ url $ no_download $ dir),
           Term.info "pitzulit" ~version:"v0.1" ~doc))
