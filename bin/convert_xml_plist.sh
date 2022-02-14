#!/usr/bin/env bash

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

cmd=""

# Check for plist converters
if command -v plutil &> /dev/null; then
    cmd="plutil"
elif command -v ply &> /dev/null; then
    cmd="ply"
elif command -v plistutil &> /dev/null; then
    cmd="plistutil"
else
    echo "ERROR: convert_xml_plist.sh: Please install either plutil, ply, or libplist-utils."
    exit
fi

# Get all the .plists and .strings in the project and its sub projects
results=$(find "$directory" \( -name \*.plist -o -name \*.strings \))
results_array=($results)

# Check to see if files are in xml format or binary
for i in "${results_array[@]}"; do
    # Grab printable characters from file's bytes
    head=$(od -c $i | head)
    # Strip any non-letter charcters
    clean_head=${head//[^[:alpha:]]/}
    # bplist's have an 8 byte header ([bplist##] where ## is the version)
    # Since we only care to see if the file is in binary format, we're
    # going to check for just 6 bytes (i.e., ignore the version)
    magic_bytes=${clean_head:0:6}

    # If file wasn't in binary format, convert it
    if ! [[ ${magic_bytes,,} == "bplist" ]]; then
        if [[ $cmd == "plutil" ]]; then
            plutil -convert binary1 $i
        elif [[ $cmd == "ply" ]]; then
            ply -c binary $i
        else
            plistutil -i $i -f bin -o $i
        fi
    fi
done
