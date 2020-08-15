Project is no longer being developed. I recommend taking a look at this; https://github.com/HaveAGitGat/Tdarr

![plexEncode.sh](https://image.ibb.co/jmZzxH/plex_Encode_logo.png)
### Usage:
#### Plex DVR
Setup: Plex \ Settings \ Live TV & DVR \ DVR Settings \ Postprocessing Script = full path to the script
#### Shell
```
plexEncode.sh <file> <encoder> <remove_original>

<encoder>           = ffmpeg    # .mkv file output. modify $ffmpeg_options to your specs.
                    = handbrake # .m4v file output. modify $handbrake_options to your specs.
<remove_original>   = 0         # keep original input file.
                    = 1         # delete original input file.
```
#### Shell Examples:
```
# encode a single file using default encoder and original file handling set in script
plexEncode.sh "file"

# encode a single file using handbrake, remove the original file
plexEncode.sh "file" handbrake 1

# encode a single file using ffmpeg, keep the original file
plexEncode.sh "file" ffmpeg 0

# loop thru a directory containing multiple .ts files
for i in *.ts; do plexEncode.sh "$i" ; done
```
#### Sonarr
![Sonarr](https://image.ibb.co/f9zrcH/plex_Encode_sonarr.png)
#### Radarr
![Radarr](https://image.ibb.co/eWAKWc/plex_Encode_radarr.png)

#### Required:
Script to add handbrake/ffmpeg/mediainfo/etc packages to your plex/sonarr/radarr dockers; https://gist.github.com/scrathe/ba29e50d95f71bfb207ccf6f74a425a7

#### Sample Logging:
![example](https://image.ibb.co/igfF97/plex_Encode_example.png)
