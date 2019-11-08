open Containers

let find_file_fuzzy pattern =
  let pattern = String.Find.compile pattern in
  Sys.readdir "."
  |> Array.find_map
    (fun s ->
       if Int.(String.Find.find ~pattern s <> -1) then Some s
       else None)

let eprint msg =
  IO.write_line stderr msg
