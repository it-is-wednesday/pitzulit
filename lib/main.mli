type error = [ `Eyed3Error of int | `FfmpegError of int | `YoutubeDlError of int ]

(** Prepare filesystem for extracting tracks from a new album:
    - Download the album as audio via youtube-dl (saved as "album.mp3" in current dir)
    - Figure out the [Album.t]
    - Create target directory
    - Fetch cover art (video thumbnail)

    If no errors occured, returns a tuple of: [Album.t], cover file path, target directory *)
val setup :
  url:string ->
  dir:string ->
  no_download:bool ->
  (Album.t * string * string, [> `YoutubeDlError of int ]) result

(* Assumes an "album.mp3" file exists in current dir (created by [Pitzulit.Main.setup]).
   extracts the given track into its own file via ffmpeg, then tags it via eyeD3. *)
val handle_track :
  Track.t ->
  artist:string ->
  album:string ->
  dir:string ->
  cover_file:string ->
  no_extract:bool ->
  verbose:bool ->
  (unit, [> `Eyed3Error of int | `FfmpegError of int ]) result
