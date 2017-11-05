import os
import re
import sys
from typing import List

NO_TIMESTAMPS_ERR = "Description doesn't contain song timestamps :("

FilePath = str


def download_album(url: str) -> (FilePath, FilePath):
        """
        :param url: url of a full album video on youtube
        :return: a tuple containing:
                        1. path denoting a text file containing the video's description
                        2. path denoting a WAV file containing the whole video's audio
        """
        download_path = "downloaded"

        description_file = download_path + ".description"
        album_file = download_path + ".wav"

        os.system("youtube-dl '{url}' -x --write-description -o '{download_path}.%(ext)s' --audio-format wav"
                  .format(url=url, download_path=download_path))

        return album_file, description_file


def minutes_to_seconds(time) -> int:
        """
        :param time: seconds/minutes (can be either a string in MM:SS format or an integer)
        :return: if time was an integer it returns itself; otherwise it's converted to seconds
        """
        ptime = str(time)
        if ':' in ptime:
                s = ptime.split(':')
                minutes = s[0]
                seconds = s[1]
                return int(minutes) * 60 + int(seconds)
        return int(ptime)


def album_length(file_path: FilePath) -> int:
        """
        :param file_path: path denoting a full album's audio file
        :return: the album's length in seconds
        """
        os.system("ffprobe -i {file_path} -show_entries format=duration -v quiet -of csv='p=0' > length"
                  .format(file_path=file_path))
        result = open("length").read()
        os.remove("length")
        return int(float(result))


def extract_track(file_path: str, song_beginning: str, song_end: str, number: int) -> FilePath:
        """
        :param file_path: path denoting a full album's audio file
        :param song_beginning: beginning of a song we'd like to extract (either in minutes or seconds)
        :param song_end: end of a song we'd like to extract (either in minutes or seconds)
        :param number: track number
        :return: path denoting an audio file containing the extracted track
        """
        os.system("avconv -i '{input_file}' -ss {beginning} -t {end} '{output_file}' -y"
                  .format(beginning=song_beginning,
                          end=int(minutes_to_seconds(song_end)) - int(minutes_to_seconds(song_beginning)),
                          input_file=file_path,
                          output_file=str(number) + ".ogg"))
        return str(number) + ".ogg"


def chop(timestamps: List[str], file_path: str) -> List[FilePath]:
        """
        :param timestamps: a list of timestamps for each track in the album, for example: ["0:00", "4:30", "8:12"]
        :param file_path: path denoting an audio file containing the album's audio
        :return: Extracts each track in the album into a separate file based on timestamps and returns a list of paths,
                 each path referring to a different track file
        """

        def e(start, end, number: int) -> FilePath:
                return extract_track(file_path, start, end, number)

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
        # find timestamps in the description
        timestamps = re.findall(r'\d\d:\d\d', video_description)

        print(chop(timestamps, album_path))

        os.remove(album_path)
        os.remove(description_path)
