import os
import re
import sys
from typing import List

NO_TIMESTAMPS_ERR = "Description doesn't contain song timestamps :("

FilePath = str


def download_album(url: str) -> (FilePath, FilePath):
        download_path = "downloaded"

        description_file = download_path + ".description"
        album_file = download_path + ".wav"

        os.system("youtube-dl '{url}' -x --write-description -o '{download_path}.%(ext)s' --audio-format wav"
                  .format(url=url, download_path=download_path))

        return album_file, description_file


def minutes_to_seconds(time) -> int:
        ptime = str(time)
        if ':' in ptime:
                s = ptime.split(':')
                minutes = s[0]
                seconds = s[1]
                return int(minutes) * 60 + int(seconds)
        return int(ptime)


def album_length(file_path: FilePath) -> int:
        os.system("ffprobe -i {file_path} -show_entries format=duration -v quiet -of csv='p=0' > length"
                  .format(file_path=file_path))
        result = open("length").read()
        os.remove("length")
        return int(float(result))


def extract_song(file_path: str, song_beginning: str, song_end: str, number: int) -> FilePath:
        os.system("avconv -i '{input_file}' -ss {beginning} -t {end} '{output_file}' -y"
                  .format(beginning=song_beginning,
                          end=int(minutes_to_seconds(song_end)) - int(minutes_to_seconds(song_beginning)),
                          input_file=file_path,
                          output_file=str(number) + ".ogg"))
        return str(number) + ".ogg"


def chop(timestamps: List[str], file_path: str) -> List[FilePath]:
        def e(start, end, number: int) -> FilePath:
                return extract_song(file_path, start, end, number)

        ts = timestamps
        songs_num = len(ts) + 1

        result = []
        if songs_num == 0:
                print(NO_TIMESTAMPS_ERR)
        elif songs_num == 1:
                result.append(e(0, ts[0], 1))
                result.append(e(ts[0], album_length(file_path), 2))
        else:
                for i in range(1, songs_num):
                        if i == songs_num - 1:
                                result.append(e(ts[-1], album_length(file_path), songs_num - 1))
                        else:
                                result.append(e(ts[i - 1], ts[i], i))
        return result


if __name__ == '__main__':
        args = sys.argv
        video_url = args[1]

        album_path, description_path = download_album(video_url)

        video_description = open(description_path).read()
        timestamps = re.findall(r'\d\d:\d\d', video_description)

        print(chop(timestamps, album_path))

        os.remove(album_path)
        os.remove(description_path)
