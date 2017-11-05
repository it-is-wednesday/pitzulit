import os
import re
import sys
from typing import List

NO_TIMESTAMPS_ERR = "Description doesn't contain song timestamps :("


def download_album(url: str) -> (str, str):
        download_path = "downloaded"
        description_path = download_path + ".description"
        album_path = download_path + ".wav"

        os.system("youtube-dl {url} -x --write-description -o '{download_path}.%(ext)s' --audio-format wav"
                  .format(url=url, download_path=download_path))

        return album_path, description_path


def extract_song(file_path: str, song_beginning: str, song_end: str, number: int):
        os.system("ffmpeg -y -ss {beginning} -t {end} -i \"{input_file}\" {output_file}"
                  .format(beginning=song_beginning,
                          end=int(minutes_to_seconds(song_end)) - int(minutes_to_seconds(song_beginning)),
                          input_file=file_path,
                          output_file=str(number) + ".ogg"))


def minutes_to_seconds(time: str) -> int:
        ptime = time if type(time) is str else str(time)
        if ':' in ptime:
                s = ptime.split(':')
                minutes = s[0]
                seconds = s[1]
                return int(minutes) * 60 + int(seconds)
        return ptime


def album_length(file_path: str) -> int:
        os.system("ffprobe -i {file_path} -show_entries format=duration -v quiet -of csv='p=0' > length"
                  .format(file_path=file_path))
        result = open("length").read()
        print(result)
        os.remove("length")
        return int(float(result))


def chop(timestamps: List[str], file_path: str):
        def e(start, end, number):
                extract_song(file_path, start, end, number)

        ts = timestamps
        songs_num = len(ts)

        if songs_num == 0:
                print(NO_TIMESTAMPS_ERR)
        elif songs_num == 1:
                e(0, ts[0], 1)
                e(ts[0], album_length(file_path), 2)
        else:
                e(0, ts[1], 1)
                for i in range(1, songs_num - 1):
                        e(ts[i], ts[i + 1], i + 1)
                        print("\n\n" + str(i + 1) + "\n\n")
                e(ts[-1], album_length(file_path), songs_num)


args = sys.argv
video_url = args[1]

album_path, description_path = download_album(video_url)

video_description = open(description_path).read()

timestamps = re.findall(r'\d\d:\d\d', video_description)

chop(timestamps, album_path)

os.remove(album_path)
os.remove(description_path)
