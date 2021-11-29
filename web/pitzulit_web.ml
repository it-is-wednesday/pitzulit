open Opium

let () =
  let port = 3420 in

  Printf.printf "API serving on port %d\n" port;
  flush stdout;

  App.empty
  |> App.port port
  |> App.run_command
