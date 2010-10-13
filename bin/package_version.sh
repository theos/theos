#!/bin/bash

while getopts ":e:1c:" flag; do
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
	esac
done

if [[ -z "$CONTROL" || ! -f "$CONTROL" ]]; then
	echo "$0: Please specify a control file with -c." 1>&2
	exit 1;
fi

if [[ ! -d "${FW_PROJECT_DIR}/.theos/packages" ]]; then
	if [[ -d "${FW_PROJECT_DIR}/.debmake" ]]; then
		mkdir -p "${FW_PROJECT_DIR}/.theos"
		mv "${FW_PROJECT_DIR}/.debmake" "${FW_PROJECT_DIR}/.theos/packages"
	else
		mkdir -p "${FW_PROJECT_DIR}/.theos/packages"
	fi
fi

package=$(grep "^Package:" "$CONTROL" | cut -d' ' -f2)
version=$(grep "^Version:" "$CONTROL" | cut -d' ' -f2)
versionfile="${FW_PROJECT_DIR}/.theos/packages/$package-$version"
build_number=0

if [[ ! -e "$versionfile" ]]; then
	echo -n 1 > "$versionfile"
	build_number=1
else
	build_number=$(< "$versionfile")
	let build_number++
	echo -n "$build_number" > "$versionfile"
fi

buildno_part="-$build_number"
if [[ $SKIPONE -eq 1 && $build_number -eq 1 ]]; then
	buildno_part=""
fi

extra_part=""
if [[ ! -z "$EXTRAVERS" ]]; then
	extra_part="+$EXTRAVERS"
fi

sed -e "s/^Version: \(.*\)/Version: \1$buildno_part$extra_part/g" $CONTROL
