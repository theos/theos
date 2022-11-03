#!/usr/bin/env bash

set -e

# Accept 'D' flag
while getopts ":D:" flag; do
	case "$flag" in
		# Assign the arg associated with -D to $directory
		D)	directory="$OPTARG" ;;
		*)	echo "$0: Option -$OPTARG requires an argument." 1>&2
			exit 1
			;;
	esac
done

# Check that all arguments were passed
if [[ -z $directory ]]; then
	echo "Usage: $0 -D path" >&2
	exit 1
fi

# Check for plist converters
if command -v plutil &> /dev/null; then
	cmd=plutil
elif command -v ply &> /dev/null; then
	cmd=ply
elif command -v plistutil &> /dev/null; then
	cmd=plistutil
else
	printf "\e[0;36m==> \e[1;36mNotice:\e[m %s\n" \
		"Neither plutil, ply, or libplist-utils are installed, so XML plist files were not optimized."
	exit
fi

# Get all the .plists and .strings in the project and its sub projects
find "$directory" \( -name \*.plist -o -name \*.strings \) | while read i; do
	# Grab printable characters from file's bytes
	head="$(od -c "$i" | head)"
	# Strip any non-letter charcters
	clean_head="${head//[^[:alpha:]]/}"
	# bplist's have an 8 byte header ([bplist##] where ## is the version)
	# Since we only care to see if the file is in binary format, we're
	# going to check for just 6 bytes (i.e., ignore the version)
	magic_bytes="${clean_head:0:6}"

	# If file wasn't in binary format, convert it
	if ! [[ $magic_bytes == bplist ]]; then
		if [[ $cmd == plutil ]]; then
			plutil -convert binary1 "$i"
		elif [[ $cmd == ply ]]; then
			ply -c binary "$i"
		else
			plistutil -i "$i" -f bin -o "$i"
		fi
	fi
done
