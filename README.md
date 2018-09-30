# Pitzulit
Extract tracks from an album hosted on YouTube (or any host supported by [youtube-dl](https://github.com/rg3/youtube-dl))
based on the timestamps in its description.
Expects `ffmpeg` and `youtube-dl` to exist in your $PATH.

## Building
```
opam install containers lwt.unix yojson re
dune build src/main.exe
```

## Usage
```
_build/default/src/main.exe URL
```
Provided the video this URL leads into is titled X, running this command will result in a new directory named X under the current working directory. Inside this directory, a couple of fresh tracks will be waiting for you, named according to the track titled found in the description.

## Cool things to wish for
- [ ] MP3 Tags
- [ ] Not depending on foreign executables
    - [ ] wget
    - [ ] ffmpeg
    - [ ] youtube-dl
