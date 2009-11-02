#!/bin/bash
required=0
persistence=/tmp/dhbxxx

while getopts ":p:r" flag; do
	case "$flag" in
		:)	echo "$0: Option -$OPTARG requires an argument." 1>&2
			exit 1
			;;
		\?)	echo "$0: Option -$OPTARG unrecognized." 1>&2
			exit 1
			;;
		p)	persistence="$OPTARG" ;;
		r)	required=1 ;;
	esac
done
shift $((OPTIND-1))
cmd=$*

#rm -f $persistence

if type fakeroot-ng &> /dev/null; then
	fakeroot="fakeroot-ng -p $persistence -- "
elif type fakeroot &> /dev/null; then
	fakeroot="fakeroot -s $persistence -- "
else
	if [[ $required -eq 1 ]]; then
		fakeroot=""
	else
		fakeroot=": "
	fi
fi

#echo $fakeroot $cmd
$fakeroot $cmd
