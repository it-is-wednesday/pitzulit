open Cmdliner

let no_download =
  let doc = "Don't run youtube-dl at all; only parse existing audio and JSON files that were already download in previous runs" in
  Arg.(value & flag & info ["no-download"] ~doc)

let no_extract =
  let doc = "Don't extract tracks out of the album file, just tag them" in
  Arg.(value & flag & info ["no-extract"] ~doc)

let url =
  let doc = "URL of YouTube video (or any other host supported by youtube-dl)" in
  Arg.(required & pos 0 (some string) None & info [] ~doc)

let dir =
  let doc = "Directory in which all the fun will happen" in
  Arg.(value & opt string "[named after album title]" & info ["d"; "dir"] ~docv:"PATH" ~doc)

let verbose =
  let doc = "Pass verbose flags to ffmpeg and eyeD3" in
  Arg.(value & flag & info ["v"; "verbose"] ~doc)

let run main_func =
  (* Cmdliner deliberately has no option to use the plain help page by default, so this weird hack
     is necessary :( See https://github.com/dbuenzli/cmdliner/pull/26 *)
  if Array.mem "--help" Sys.argv then
    Unix.putenv "TERM" "dumb";

  let doc = "Extract tracks from an album hosted on YouTube" in
  Term.(exit @@ eval
          (Term.(const main_func $ url $ dir $ no_download $ no_extract $ verbose),
           Term.info "pitzulit" ~version:"v0.1" ~doc))
