type error = [ `Eyed3Error of int | `FfmpegError of int | `YoutubeDlError of int ]

val setup :
  string ->
  String.t ->
  bool ->
  (Album.t * string * string, [> `YoutubeDlError of int ]) result

val handle_track :
  Track.t ->
  Album.t ->
  dir:string ->
  cover_file:string ->
  no_extract:bool ->
  verbose:bool ->
  (unit, [> `Eyed3Error of int | `FfmpegError of int ]) result
