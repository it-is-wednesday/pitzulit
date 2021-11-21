module Time = struct
  type t =
    | Beginning of int (* track's end timestamp in seconds *)
    | Middle of int * int (* beginning timestamp and end in seconds *)
    | End of int (* track's timestamp (from the beginning!) in seconds *)
end

type t = {
  title: string;
  time: Time.t;
  track_num: int;
}


let extract album_file dir {title; time; _} =
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
       "ffmpeg -loglevel info -hide_banner -y %s -i '%s' '%s/%s.mp3'"
       range
       (String.escaped album_file)
       dir
       title) |> ignore
