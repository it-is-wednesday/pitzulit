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


let extract album_file dir {title; time; _} verbose =
  let range =
    let open Time in
    match time with
    | Beginning end_ -> Printf.sprintf "-t %d" end_
    | Middle (beg, end_) -> Printf.sprintf "-ss %d -to %d" beg end_
    | End beg -> Printf.sprintf "-ss %d" beg
  in
  let loglevel = if verbose then "info" else "warning" in
  let exit_code =
    Printf.sprintf
      "ffmpeg -hide_banner -y %s -i '%s' '%s/%s.mp3' -loglevel %s"
      range (String.escaped album_file) dir title loglevel
    |> Sys.command
  in
  match exit_code with
  | 0 -> Ok ()
  | code -> Error (`FfmpegError code)
