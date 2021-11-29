watch-web:
    watchexec --clear --restart --watch web/ 'dune build && _build/default/web/pitzulit_web.exe'
