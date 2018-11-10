let lwt_shell cmd =
  let open Lwt.Infix in
  let run_and_wait cmd =
    cmd |> Lwt_process.shell |> Lwt_process.exec >|= fun _ -> ()
  in
  Printf.ksprintf run_and_wait cmd


let debug (s : string) =
  print_endline s;
  s


let failwithf fmt =
  Printf.ksprintf failwith fmt

    
let select_one_exn selector node =
  match Soup.select_one selector node with
  | Some ummm -> ummm
  | None -> failwithf "Couldn't find any node that belongs to the class %s" selector
