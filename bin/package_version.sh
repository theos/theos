#!/bin/bash

UPDATE=1
SKIPONE=0
JUST_ECHO_VERSION=0
KEEP_LAST=0

function build_num_from_file {
	version=$(< "$1")
	version=${version##*-}
	version=${version%%+*}
	version=${version%%~*}
	echo -n "$version"
}

while getopts ":e:1c:nok" flag; do
	case "$flag" in
		:)	echo "$0: Option -$OPTARG requires an argument." 1>&2
			exit 1
			;;
		\?)	echo "$0: What're you talking about?" 1>&2
			exit 1
			;;
		e)	EXTRAVERS="$OPTARG" ;;
		c)	CONTROL="$OPTARG" ;;
		1)	SKIPONE=1 ;;
		n)	UPDATE=0 ;;
		o)	JUST_ECHO_VERSION=1 ;;
		k)	KEEP_LAST=1 ;;
	esac
done

if [[ -z "$CONTROL" || ! -f "$CONTROL" ]]; then
	echo "$0: Please specify a control file with -c." 1>&2
	exit 1;
fi

if [[ ! -d "${THEOS_PROJECT_DIR}/.theos/packages" ]]; then
	if [[ -d "${THEOS_PROJECT_DIR}/.debmake" ]]; then
		mkdir -p "${THEOS_PROJECT_DIR}/.theos"
		mv "${THEOS_PROJECT_DIR}/.debmake" "${THEOS_PROJECT_DIR}/.theos/packages"
	else
		mkdir -p "${THEOS_PROJECT_DIR}/.theos/packages"
	fi
fi

package=$(grep "^Package:" "$CONTROL" | cut -d' ' -f2-)
version=$(grep "^Version:" "$CONTROL" | cut -d' ' -f2-)
versionfile="${THEOS_PROJECT_DIR}/.theos/packages/$package-$version"
build_number=0

if [[ ! -e "$versionfile" ]]; then
	build_number=1
else
	build_number=$(build_num_from_file "$versionfile")
	let build_number++
fi

buildno_part="-$build_number"
if [[ $SKIPONE -eq 1 && $build_number -eq 1 ]]; then
	buildno_part=""
fi

extra_part=""
if [[ ! -z "$EXTRAVERS" ]]; then
	extra_part="+$EXTRAVERS"
fi

full_version="$version$buildno_part$extra_part"
if [[ $KEEP_LAST -eq 1 ]]; then
	if [[ -e "$versionfile" ]]; then
		full_version=$(< "$versionfile")
	else
		full_version="none"
	fi
fi

if [[ $UPDATE -eq 1 && $KEEP_LAST -eq 0 ]]; then
	echo -n "$full_version" > "$versionfile"
fi

if [[ $JUST_ECHO_VERSION -eq 1 ]]; then
	echo "$full_version"
else
	sed -e "s/^Version: \(.*\)/Version: $full_version/g" $CONTROL
fi
