# Pitzulit
Extract tracks from an album hosted on YouTube (or any host supported by [youtube-dl](https://github.com/rg3/youtube-dl))
based on the timestamps in its description.
Expects [`ffmpeg`](https://ffmpeg.org/), [`eyeD3`](https://eyed3.readthedocs.io/en/latest/installation.html), `wget` and [`youtube-dl`](http://rg3.github.io/youtube-dl/) to exist in your $PATH.

## Building
```
opam install containers lwt yojson re dune tls cohttp-lwt-unix
dune build src/main.exe
```

## Usage
```
_build/default/src/main.exe URL
```
Running this command will create a new directory titled after the album's name that contains audio files, each file being a track from the album.

## Cool things to wish for
- [X] MP3 Tags
- [ ] Progress bar
- [ ] Tests
- [ ] Useful error messages
- [ ] Ensure essential binaries are available
- [X] Provide an interface for searching and selecting videos
	  instead of manually feeding their URL
- [ ] Think of a sexier name
- [ ] Web interface?
