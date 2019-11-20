open Containers
open Pitzulit


let%test "parse description" =
  let example = Yojson.Basic.from_string {|
{
  "description": "1. 00:00 first\n2. 00:02 second",
  "title": "artist - title",
  "thumbnail": "http://www.bruh.com/url.png"
}
|} |> Pitzulit.Album.from_info_json in
  let expected =
    let tracks =
      Track.[{ title = "first"; time = Time.Beginning 2; track_num = 1 }
            ;{ title = "second"; time = Time.End 2; track_num = 2 }]
    in
    Album.{
      title = "title";
      artist = "artist";
      cover_art_url = Uri.of_string "http://www.bruh.com/url.png";
      tracks = tracks
    }
  in
  Equal.poly example expected
