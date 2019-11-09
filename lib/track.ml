open Containers

module Time = struct
  type t =
    | Beginning of int (* track's end timestamp in seconds *)
    | Middle of int * int (* track's beginning timestamp and end timestamp in seconds *)
    | End of int (* track's timestamp (from the beginning!) in seconds *)
end

type t = {
  title: string;
  time: Time.t;
  track_num: int;
}


let to_string track =
  let beg, end_ =
    let open Time in
    match track.time with
    | Beginning x -> 0, x
    | Middle (x, y) -> x, y
    | End x -> x, -1
  in
  Printf.sprintf "%s (%d - %d)" track.title beg end_


let extract album_file {title; time; _} =
  let range =
    let open Time in
    match time with
    | Beginning end_ -> Printf.sprintf "-t %d" end_
    | Middle (beg, end_) -> Printf.sprintf "-ss %d -to %d" beg end_
    | End beg -> Printf.sprintf "-ss %d" beg
  in
  let title = String.escaped title in
  Sys.command
    (Printf.sprintf
       "ffmpeg -loglevel info -hide_banner -y %s -i '%s' '%s.mp3'"
       range
       (String.escaped album_file)
       title) |> ignore;
