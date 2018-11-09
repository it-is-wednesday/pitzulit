val track_infos_from_desc : string -> int -> Pitzulit_types.track_info list
(** [track_infos_from_desc desc video_duration] accepts a video description
    [desc] and this video's duration in seconds. The description is expected
    to contain timestamps of the following format: 
    1. "Warped" 0:00
    2. "Aeroplane" 5:07
    3. "Deep Kick" 9:55
    ... *)


val extract_title_data : string -> string * string
(** [extract_title_data video_title] accepts a string that represents an
    album's title, meaning it has the format of "$Artist - $AlbumName",
    then returns a tuple of the artist's name and the album's name.*)
