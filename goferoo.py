import os
import re
import subprocess
import sys
import argparse
from typing import List

NO_TIMESTAMPS_ERR = "Description doesn't contain song timestamps :("

FilePath = str


def download_audio(url: str) -> (FilePath, FilePath):
        """
        :param url: url of a full album video on youtube/any youtube-dl supported service
        :return: path denoting a WAV file containing the whole video's audio
        """
        downloaded_album_path = "goferoo_downloaded_audio.wav"

        args = ["youtube-dl", url, "-o", downloaded_album_path, "-x", "--audio-format", "wav"]
        subprocess.call(args)

        return downloaded_album_path


def get_video_description(url: str) -> str:
        p = subprocess.Popen(["youtube-dl", url, "--skip-download", "--get-description"], stdout=subprocess.PIPE)
        output, err = p.communicate()
        return output.decode()


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
        # This hack is used because subprocess.Popen can't capture avprobe's output normally for some reason
        length_out_file = "goferoo_audio_length_output"
        os.system("avprobe -i {input} -show_entries format=duration -v quiet -of csv='p=0' > {output}".format(
                input=file_path,
                output=length_out_file
        ))

        result = open(length_out_file).read()
        os.remove(length_out_file)
        return int(float(result))


def extract_track(file_path: FilePath, track_beginning: str, track_end: str, number: int) -> FilePath:
        """
        :param file_path: path denoting a full album's audio file
        :param track_beginning: beginning of a song we'd like to extract (either in minutes or seconds)
        :param track_end: end of a song we'd like to extract (either in minutes or seconds)
        :param number: track number
        :return: path denoting an audio file containing the extracted track
        """

        output_file = str(number) + ".ogg"
        track_length = str(int(minutes_to_seconds(track_end)) - int(minutes_to_seconds(track_beginning)))

        args = ["avconv", "-i", file_path, "-ss", track_beginning, "-t", track_length, output_file, "-y"]
        subprocess.call(args)

        return str(number) + ".ogg"


def chop(timestamps: List[str], file_path: FilePath) -> List[FilePath]:
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
        parser = argparse.ArgumentParser(description="Extract tracks from a full album file",
                                         formatter_class=lambda prog: argparse.HelpFormatter(
                                                 prog,
                                                 max_help_position=9999,
                                                 width=90
                                         ))

        parser.add_argument("-u", "--url",
                            metavar="URL",
                            help="URL to fetch audio and timestamps from. \
                                  Needs to be a service supported by youtube-dl.")

        parser.add_argument("-a", "--audio-file",
                            metavar="FILE",
                            help="file containing audio. \
                                  if used along with -u, will only fetch the description from the specified URL.")

        parser.add_argument("-t", "--timestamps-file",
                            metavar="FILE",
                            help="file containing timestamps. \
                                  if used along with -u, will only fetch the audio from the specified URL.")

        args = vars(parser.parse_args())

        if args["url"] is not None:
                album_path = args["audio_file"] if args["audio_file"] is not None else download_audio(url=args["url"])
                timestamps = args["timestamps_file"] if args["timestamps_file"] is not None else get_video_description(url=args["url"])
        else:
                if args["audio_file"] is None or args["timestamps_file"] is None:
                        print("No audio/timestamps provided.")
                        sys.exit(2)

                timestamps = args["timestamps_file"]
                album_path = args["audio_file"]
                try:
                        timestamps_file = open(args["timestamps_file"])
                        timestamps = timestamps_file.read()
                except FileNotFoundError:
                        print("Timestamps file doesn't exist!")
                        sys.exit(2)

        chop(
                # find timestamps in the description
                timestamps=re.findall(r'\d\d:\d\d', timestamps),
                file_path=album_path
        )

        os.remove(album_path)
