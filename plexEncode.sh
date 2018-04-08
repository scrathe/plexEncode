#!/bin/bash
shopt -s extglob
# plexEncode.sh
# ██████╗ ██╗     ███████╗██╗  ██╗███████╗███╗   ██╗ ██████╗ ██████╗ ██████╗ ███████╗
# ██╔══██╗██║     ██╔════╝╚██╗██╔╝██╔════╝████╗  ██║██╔════╝██╔═══██╗██╔══██╗██╔════╝
# ██████╔╝██║     █████╗   ╚███╔╝ █████╗  ██╔██╗ ██║██║     ██║   ██║██║  ██║█████╗  
# ██╔═══╝ ██║     ██╔══╝   ██╔██╗ ██╔══╝  ██║╚██╗██║██║     ██║   ██║██║  ██║██╔══╝  
# ██║     ███████╗███████╗██╔╝ ██╗███████╗██║ ╚████║╚██████╗╚██████╔╝██████╔╝███████╗
# ╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝                                                                                   
# Home: https://gist.github.com/scrathe
# Usage:
# Plex DVR: Plex \ Settings \ Live TV & DVR \ DVR Settings \ Postprocessing Script = full path to the script
#
# Shell:    plexEncode.sh <file> <encoder> <remove_original>
#
#           <encoder>   = ffmpeg    # .mkv file output. modify $ffmpeg_options to your specs.
#                       = handbrake # .m4v file output. modify $handbrake_options to your specs.
#           <remove_original>   = 0 # keep original input file.
#                               = 1 # delete original input file.
#
# Sonarr:   plexEncode.sh <unused> <encoder> <remove_original> sonarr
#
#           Settings \ Connect \ plexEncode \ Path = full path to the script
#           On Download = yes
#           On Upgrade = yes
#           Arguments = x ffmpeg 1 sonarr
#
# Radarr:   plexEncode.sh <unused> <encoder> <remove_original> radarr
#
#           Settings \ Connect \ plexEncode \ Path = full path to the script
#           On Download = yes
#           On Upgrade = yes
#           Arguments = x ffmpeg 1 radarr
#
# Required: script to add handbrake/ffmpeg/mediainfo/etc packages to your plex/sonarr/radarr dockers; https://gist.github.com/scrathe/ba29e50d95f71bfb207ccf6f74a425a7

plex_logfile="/media/scripts/logs/plexEncode.log"
plex_lockfile="/media/scripts/logs/plexEncode.lock" # used to limit Plex DVR simultaneous encodes
sonarr_logfile="/tv/scripts/logs/plexEncode.log"
radarr_logfile="/movies/scripts/logs/plexEncode.log"

# Optional: script to push notifications; https://github.com/jnwatts/pushover.sh
#           enable/disable at very bottom of script

enable_push_notification="1" # 0 = disable
plex_push="/media/scripts/pushover.sh"
sonarr_push="/tv/scripts/pushover.sh"
radarr_push="/movies/scripts/pushover.sh"

# Shell Examples:
# /media/scripts/plexEncode/plexEncode.sh "file" ffmpeg 0 # ffmpeg encoder, keep original input file
# for i in *.ts; do /media/scripts/plexEncode/plexEncode.sh "$i" ; done # loop thru all *.ts files

echo_log() {
	if [[ ! -e $logfile ]]; then
		touch "$logfile"
	fi
	echo "`date --iso-8601=seconds` $script: $file: ${*}"
	echo "`date --iso-8601=seconds` $script: $file: ${*}" >> "$logfile"
}

# check for $1 parameter = filename
file="$1"
if [[ -z $1 ]]; then
	echo "ERROR, no filename specified"
	exit 1
fi

# check for $2 parameter = encoder type. plex does not pass $2, set default below.
encoder="$2"
if [[ -z $encoder ]]; then
	# set default encoder
	# handbrake
	# ffmpeg
	encoder="ffmpeg"
fi

# check for $3 parameter = remove original input file. plex does not pass $3, set default below.
remove_original=$3
if [[ -z $3 ]]; then
	# set default behavior
	# 0 = keep input file
	# 1 = remove input file
	remove_original=1
fi

# check for mediainfo
mediainfo=$(which mediainfo)
if [[ $? != 0 ]]; then
	echo_log "ERROR, mediainfo missing"
	exit 1
fi

check_skipped_shows(){
	# skip shows you don't archive
	regex="^(WGN Evening News|WGN Weekend Evening News|CNN News|CNN Tonight).*$"
	if [[ $file =~ $regex ]]; then
		echo_log "Skipping"
		exit 1
	fi
}

push_notification(){
	if [[ ! -z $push_script ]]; then
		$push_script "$name | $speed min | $size %"
	fi
}

encode_file(){
	height="$(mediainfo --Inform='Video;%Height%' "$file")"
	if [[ ! -z $height ]]; then
		height="[${height}p]"
		echo_log "Input Resolution: $height"
	fi

	# name = filename without extension
	name=$(echo ${file%.*})
	# strip trailing space or hyphen   
	name=$(echo $name | sed -r 's/[- ]{1,}$//g')
	
	if [[ $encoder = "handbrake" ]]; then
		# output file extension
		ext="m4v"
		atomic_file="atomicfile_${RANDOM}.$ext"

		# check for handbrake
		handbrake_cli=$(which HandBrakeCLI)
		if [[ $? != 0 ]]; then
			echo_log "ERROR, handbrake missing"
			exit 1
		fi

		# handbrake options https://github.com/HandBrake/HandBrake
		# https://en.wikipedia.org/wiki/H.264/MPEG-4_AVC#Levels
		handbrake_options="-e x264 -q 20 --optimize --srt-lang eng --native-language eng --native-dub -f mp4 --decomb --loose-anamorphic --modulus 2 -m --x264-preset medium --h264-profile high --h264-level 4.1"

		# modify handbrake options to suit input file audio
		channels="$(mediainfo --Inform='Audio;%Channels%' "$file" | sed 's/[^0-9].*$//')"
		if [[ $channels > 2 ]]; then
			handbrake_options="$handbrake_options --aencoder ca_aac,copy:ac3,copy:dts,copy:dtshd"
		elif [ "$(mediainfo --Inform='General;%Audio_Format_List%' "$file" | sed 's| /.*||')" == 'AAC' ]; then
			handbrake_options="$handbrake_options --aencoder copy:aac"
		fi

		# encode
		start=$(date +%s%N)
		echo "" | $handbrake_cli -i "$file" -o "$atomic_file" $handbrake_options > /dev/null 2>&1
		if [[ $? != 0 ]]; then
			echo_log "ERROR, HandBrake exit code $?"
			rm "$atomic_file"
            rm "$lockfile"
			exit 1
		fi
		end=$(date +%s%N)
	elif [[ $encoder = "ffmpeg" ]]; then
		# output file extension
		ext="mkv"
		atomic_file="atomicfile_${RANDOM}.$ext"
		
		# check for ffmpeg
		ffmpeg=$(which ffmpeg)
		if [[ $? != 0 ]]; then
			echo_log "ERROR, ffmpeg missing"
            rm "$lockfile"
			exit 1
		fi
		
		# ffmpeg advanced options; https://ffmpeg.org/ffmpeg.html#Advanced-options
		# ffmpeg audio stream selection; https://ffmpeg.org/ffmpeg.html#Stream-selection
        # ffmpeg x265; https://trac.ffmpeg.org/wiki/Encode/H.265
		# ffmpeg_options="-map 0 -c:a copy -c:s copy -c:v libx265 -crf 18 -preset faster -pix_fmt yuv420p10le"
		ffmpeg_options="-map 0 -c:a copy -c:s copy -c:v libx265 -crf 18 -preset faster"
        
		# encode
		start=$(date +%s%N)
		ffmpeg -i "$file" $ffmpeg_options "$atomic_file" # > /dev/null 2>&1
		if [[ $? != 0 ]]; then
			echo_log "ERROR, ffmpeg exit code $?"
			rm "$atomic_file"
            rm "$lockfile"
			exit 1
		fi
		end=$(date +%s%N)
	fi

	# input file size
	# echo_log "`ls -l "$file"`" # debug
	isize=$(du -b "$file" | awk '{print $1}')
	isizeh=$(du -h "$file" | awk '{print $1}')
	
	if [[ $remove_original = 1 ]]; then
		echo_log "Removing Original File"
		rm "$file"
		if [[ $? != 0 ]]; then
			echo_log "WARNING, original file missing: $file"
		fi
	fi
	
	mv "$atomic_file" "$name.$ext"
	if [[ $? != 0 ]]; then
		echo_log "WARNING, atomic file missing: $atomic_file"
	fi

	# output file size
	osize=$(du -b "$name.$ext" | awk '{print $1}')
	osizeh=$(du -h "$name.$ext" | awk '{print $1}')
	# calculations
	speed=$(echo "scale=2; ($end - $start) / 1000000000 / 60" | bc)
	size=$(echo "scale=2; ($isize - $osize)/$isize * 100" | bc)
	
	echo_log "Input Size: $isizeh"
	echo_log "Output Size: $osizeh"
	echo_log "Encoding Speed: $speed min"
	echo_log "Size Change: $size %"
	echo_log "Output Filename: `basename "$name.$ext"`"
}

script=$(basename $0 .sh)

case $4 in
	sonarr)
		# Sonarr execution
		# plexEncode.sh x ffmpeg 1 sonarr
		logfile="$sonarr_logfile"
		push_script="$sonarr_push"
		# $sonarr_episodefile_path is passed from Sonarr; https://github.com/Sonarr/Sonarr/wiki/Custom-Post-Processing-Scripts
		file="$sonarr_episodefile_path"
		DIR=$(dirname "$file")
		file=$(basename "$file")
		echo_log "Start: Sonarr"
		cd "$DIR"
		if [[ $? -ne 0 ]]; then
			echo_log "ERROR, cd '$DIR'"
			exit 1
		fi
		encode_file
		if [[ $enable_push_notification = "1" ]]; then
			push_notification
		fi
		echo_log "End: Sonarr"
	;;
	radarr)
		# Radarr execution
		# plexEncode.sh x ffmpeg 1 radarr
		logfile="$radarr_logfile"
		push_script="$radarr_push"
		# $radarr_moviefile_path is passed from Radarr; https://github.com/Radarr/Radarr/wiki/Custom-Post-Processing-Scripts
		file="$radarr_moviefile_path"
		DIR=$(dirname "$file")
		file=$(basename "$file")
		echo_log "Start: Radarr"
		cd "$DIR"
		if [[ $? -ne 0 ]]; then
			echo_log "ERROR, cd '$DIR'"
			exit 1
		fi
		encode_file
		if [[ $enable_push_notification = "1" ]]; then
			push_notification
		fi
		echo_log "End: Radarr"
	;;
	*)
		# Plex DVR or Shell execution
		logfile="$plex_logfile"
		push_script="$plex_push"
		DIR=$(dirname "$file")
		file=$(basename "$file")
		echo_log "Start: Shell"
		cd "$DIR"
		if [[ $? -ne 0 ]]; then
			echo_log "ERROR, cd '$DIR'"
			exit 1
		fi
		check_skipped_shows
		# prevent simultaneous encodes
		lockfile="$plex_lockfile"
		while [ -f "$lockfile" ]; do
			echo_log "Waiting for lockfile to clear"
			sleep 600 # seconds to wait
		done
		echo_log "Creating Lockfile"
		touch "$lockfile"
		encode_file
		if [[ $enable_push_notification = "1" ]]; then
			push_notification
		fi
		echo_log "Removing Lockfile"
		rm "$lockfile"
		echo_log "End: Shell"
	;;
esac
