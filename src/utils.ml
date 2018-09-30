open Containers


let lwt_shell cmd =
    let open Fun in
    Printf.ksprintf (Lwt_process.shell %> Lwt_process.exec %> fun _ -> Lwt.return_unit) cmd
