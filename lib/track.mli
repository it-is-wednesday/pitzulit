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

val extract : string -> t -> unit
