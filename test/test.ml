open Containers
open Pitzulit


let%test "parse description" =
  let result = Desc.parse_tracks_from_desc "1. 00:00 first\n2. 00:02 second" in
  let expected =
    Track.[{ title = "first"; time = Time.Beginning 2; track_num = 1 }
          ;{ title = "second"; time = Time.End 2; track_num = 2 }]
  in
  Equal.poly result expected
