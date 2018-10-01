open Containers


let lwt_shell cmd =
    let open Lwt.Infix in
    let run_and_wait cmd =
        cmd |> Lwt_process.shell |> Lwt_process.exec >|= fun _ -> ()
    in
    Printf.ksprintf run_and_wait cmd


let lwt_chain_finalize funcs =
    List.fold_left (fun a b -> fun () -> Lwt.finalize a b) (fun () -> Lwt.return_unit) funcs

