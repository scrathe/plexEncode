# plexEncode
██████╗ ██╗     ███████╗██╗  ██╗███████╗███╗   ██╗ ██████╗ ██████╗ ██████╗ ███████╗
██╔══██╗██║     ██╔════╝╚██╗██╔╝██╔════╝████╗  ██║██╔════╝██╔═══██╗██╔══██╗██╔════╝
██████╔╝██║     █████╗   ╚███╔╝ █████╗  ██╔██╗ ██║██║     ██║   ██║██║  ██║█████╗  
██╔═══╝ ██║     ██╔══╝   ██╔██╗ ██╔══╝  ██║╚██╗██║██║     ██║   ██║██║  ██║██╔══╝  
██║     ███████╗███████╗██╔╝ ██╗███████╗██║ ╚████║╚██████╗╚██████╔╝██████╔╝███████╗
╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝                                                                                 
#### Usage:
Plex DVR: Plex \ Settings \ Live TV & DVR \ DVR Settings \ Postprocessing Script = full path to the script

Shell:    plexEncode.sh <file> <encoder> <remove_original>
          <encoder>   = ffmpeg    # .mkv file output. modify $ffmpeg_options to your specs.
                      = handbrake # .m4v file output. modify $handbrake_options to your specs.
          <remove_original>   = 0 # keep original input file.
                              = 1 # delete original input file.

Sonarr:   plexEncode.sh <unused> <encoder> <remove_original> sonarr
          Settings \ Connect \ plexEncode \ Path = full path to the script
          On Download = yes
          On Upgrade = yes
          Arguments = x ffmpeg 1 sonarr

Radarr:   plexEncode.sh <unused> <encoder> <remove_original> radarr
          Settings \ Connect \ plexEncode \ Path = full path to the script
          On Download = yes
          On Upgrade = yes
          Arguments = x ffmpeg 1 radarr

#### Required: script to add handbrake/ffmpeg/mediainfo/etc packages to your plex/sonarr/radarr dockers; https://gist.github.com/scrathe/ba29e50d95f71bfb207ccf6f74a425a7

plex_logfile="/media/scripts/logs/plexEncode.log"
plex_lockfile="/media/scripts/logs/plexEncode.lock" # used to limit Plex DVR simultaneous encodes
sonarr_logfile="/tv/scripts/logs/plexEncode.log"
radarr_logfile="/movies/scripts/logs/plexEncode.log"

#### Optional: script to push notifications; https://github.com/jnwatts/pushover.sh
           enable/disable at very bottom of script

enable_push_notification="1" # 0 = disable
plex_push="/media/scripts/pushover.sh"
sonarr_push="/tv/scripts/pushover.sh"
radarr_push="/movies/scripts/pushover.sh"

#### Shell Examples:
/media/scripts/plexEncode/plexEncode.sh "file" ffmpeg 0 # ffmpeg encoder, keep original input file
for i in *.ts; do /media/scripts/plexEncode/plexEncode.sh "$i" ; done # loop thru all *.ts files
