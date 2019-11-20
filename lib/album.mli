type t = {
  title: string;
  artist: string;
  cover_art_url: Uri.t;
  tracks: Track.t list;
}

val from_info_json : Yojson.Basic.t -> t
(** [from_info_json desc] given a video info JSON (output of youtube-dl's
    --write-info-json flag), returns the parsed album value. *)
