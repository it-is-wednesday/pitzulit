open Containers

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
    | Beginning end_ -> [|"-t"; Int.to_string end_|]
    | Middle (beg, end_) -> [|"-ss"; Int.to_string beg; "-to"; Int.to_string end_|]
    | End beg -> [|"-ss"; Int.to_string beg|]
  in
  let title = String.escaped title in
  ("ffmpeg", [|"ffmpeg"; "-loglevel"; "info"; "-hide_banner";
               "-y"|]
             |> Array.append range
             |> Array.append [|"-i"; String.escaped album_file;
                               Printf.sprintf "'%s/%s.mp3'" dir title|])
  |> Lwt_process.exec ~stdout:`Dev_null
  |> Lwt.map (fun _ -> ())
