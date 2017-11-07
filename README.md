# Goferoo
Extracts songs from an album hosted on YouTube (or any host supported by [youtube-dl](https://github.com/rg3/youtube-dl))
based on song timestamps fetched from the video's description.  
`avconv`, `avprobe` and `youtube-dl` need to be available in your PATH 🔥

## Usage
```
python3 goferoo.py [-h] [-u URL] [-a audio file] [-t timestamps file]

optional arguments:
  -h, --help                       show this help message and exit
  -u URL, --url URL                URL to fetch audio and timestamps from. Needs to be a
                                   service supported by youtube-dl.
  -a FILE, --audio-file FILE       file containing audio. if used along with -u, will only
                                   fetch the description from the specified URL.
  -t FILE, --timestamps-file FILE  file containing timestamps. if used along with -u, will
                                   only fetch the audio from the specified URL.
```
For instance, `python3 -u goferoo.py https://www.youtube.com/watch?v=BVO_R8uvMhE` will download the album and write [1-8].ogg into
the current working directory.
