let lwt_shell cmd =
  let open Lwt.Infix in
  let run_and_wait cmd =
    cmd |> Lwt_process.shell |> Lwt_process.exec >|= fun _ -> ()
  in
  Printf.ksprintf run_and_wait cmd


let debug (s : string) =
  print_endline s;
  s
