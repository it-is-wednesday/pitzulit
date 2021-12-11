# run in parallel the OCaml API server and a dummy assets server for the static/ folder
watch-web:
    #!/bin/bash
    python3 -m http.server 3421 --directory web/static &
    # kill the static assets server when the watchexec process receives Ctrl-C
    trap "kill $!" SIGINT
    watchexec --restart --watch web \
        'dune build --display short && _build/default/web/pitzulit_web.exe'
