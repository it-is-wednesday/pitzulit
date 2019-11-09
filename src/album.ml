open Containers

type t = {
  title: string;
  artist: string;
  cover_art: IO.File.t;
}
