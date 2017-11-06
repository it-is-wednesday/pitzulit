# Goferoo
Extracts songs from an album hosted on YouTube (or any host supported by [youtube-dl](https://github.com/rg3/youtube-dl))
based on song timestamps fetched from the video's description.  
`avconv`, `avprobe` and `youtube-dl` need to be available in your PATH 🔥

## Usage
```
python3 goferoo.py <url>
```
For instance, `python3 goferoo.py https://www.youtube.com/watch?v=BVO_R8uvMhE` will download the album and write [1-8].ogg into
the current working directory.
