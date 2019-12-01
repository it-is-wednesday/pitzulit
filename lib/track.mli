module Time : sig
  type t =
    | Beginning of int (* track's end timestamp in seconds *)
    | Middle of int * int (* beginning timestamp and end in seconds *)
    | End of int (* track's timestamp (from the beginning!) in seconds *)
end

type t = {
  title: string;
  time: Time.t;
  track_num: int
}

(** [extract album outpath track ] extracts using ffmpeg this track's segment
    out of the whole album's file into outpath *)
val extract : string -> string -> t -> unit Lwt.t
