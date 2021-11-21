# Pitzulit
Extract tracks from an album hosted on YouTube (or any host supported by [youtube-dl](https://github.com/rg3/youtube-dl))
based on the timestamps in its description.
Expects [`ffmpeg`](https://ffmpeg.org/), [`eyeD3`](https://eyed3.readthedocs.io/en/latest/installation.html), and [`youtube-dl`](http://rg3.github.io/youtube-dl/) to exist in your $PATH.

## Usage
Download the latest release binary from https://github.com/it-is-wednesday/pitzulit/releases.
Copy a YouTube (or any other streaming service supported by youtube-dl) album video URL and pass it to Pitzulit:
```
./pitzulit URL
```
Running this command will create a new directory titled after the album's name. It will contains audio files, each file being a track from the album.

## Building
```
opam switch create pitzulit 4.12.0
opam pin . --switch pitzulit
dune build
cp _build/default/bin/main.exe pitzulit
```

## Alternatives
- [yt-dlp](https://github.com/yt-dlp/yt-dlp/) has the `--split-chapters` flag, if the video is
  divided into chapters
