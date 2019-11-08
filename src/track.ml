type time =
  | Beginning of int (* track's end timestamp in seconds *)
  | Middle of int * int (* track's beginning timestamp and end timestamp in seconds *)
  | End of int (* track's timestamp (from the beginning!) in seconds *)

type t = {
  title: string;
  time: time
}

let to_string track =
  let beg, end_ =
    match track.time with
    | Beginning x -> 0, x
    | Middle (x, y) -> x, y
    | End x -> x, -1
  in
  Printf.sprintf "%s (%d - %d)" track.title beg end_
