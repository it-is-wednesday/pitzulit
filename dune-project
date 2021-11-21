(lang dune 2.8)

(name pitzulit)
(version 0.1)

(generate_opam_files true)

(source (github it-is-wednesday/pitzulit))
(license GPLv3)
(authors "Maor Kadosh")
(maintainers "git@avocadosh.xyz")

(package
 (name pitzulit)
 (synopsis "Extract tracks from an album hosted on YouTube")
 (description "Reclaim your music from filthy streaming services")
 (depends
  (cmdliner :build)
  (containers :build)
  (cohttp-lwt-unix :build)
  (yojson :build)
  (re :build)
  (ANSITerminal :build)))
