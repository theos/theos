#!/usr/bin/env bash
required=0
persistence=/tmp/dhbxxx

is_wsl1() {
    rel="$1"
	rel_lc=$(printf '%s' "$rel" | tr '[:upper:]' '[:lower:]')
    [[ $rel_lc =~ microsoft && ! $rel =~ WSL2 ]]
}

while getopts ":p:rc" flag; do
	case "$flag" in
		:)	echo "$0: Option -$OPTARG requires an argument." 1>&2
			exit 1
			;;
		\?)	echo "$0: Option -$OPTARG unrecognized." 1>&2
			exit 1
			;;
		p)	persistence="$OPTARG" ;;
		r)	required=1 ;;
		c)	delpersistence=1 ;;
	esac
done
shift $((OPTIND-1))
cmd=$*

mkdir -p $(dirname $persistence)
touch $persistence

if [[ $delpersistence -eq 1 ]]; then
	rm -f $persistence
	exit 0
fi

if [[ "$USER" == "root" || "$EUID" -eq 0 ]]; then
	fakeroot=""
elif type fauxsu &> /dev/null; then
	fakeroot="fauxsu -p $persistence -- "
elif type fakeroot-ng &> /dev/null; then
	fakeroot="fakeroot-ng -p $persistence -- "
elif type fakeroot &> /dev/null; then
	# favor fakeroot backend with greatest support
	# (circumvents harsher tcp restrictions on some distros (e.g., Fedora 41))
	if type fakeroot-sysv &> /dev/null && ! is_wsl1 "$(uname -r)"; then
		fakeroot="fakeroot-sysv -i $persistence -s $persistence -- "
	# no -sysv on WSL1, so favor TCP
	elif is_wsl1 "$(uname -r)"; then
		fakeroot="fakeroot-tcp -i $persistence -s $persistence -- "
	else
		fakeroot="fakeroot -i $persistence -s $persistence -- "
	fi
else
	if [[ $required -eq 1 ]]; then
		fakeroot=""
	else
		fakeroot=": "
	fi
fi

#echo $fakeroot $cmd
$fakeroot $cmd
