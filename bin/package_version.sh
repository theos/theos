#!/bin/bash

while getopts ":e:1c:b:v" flag; do
	case "$flag" in
		:)	echo "$0: Option -$OPTARG requires an argument." 1>&2
			exit 1
			;;
		\?)	echo "$0: What're you talking about?" 1>&2
			exit 1
			;;
		b)	BUMP="$OPTARG" ;;
		e)	EXTRAVERS="$OPTARG" ;;
		c)	CONTROL="$OPTARG" ;;
		v)	ONLYVERSION=1 ;;
		1)	SKIPONE=1 ;;
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

package=$(grep "^Package:" "$CONTROL" | cut -d' ' -f2)
version=$(grep "^Version:" "$CONTROL" | cut -d' ' -f2)
versionfile="${THEOS_PROJECT_DIR}/.theos/packages/$package-$version"
build_number=0

if [[ ! -e "$versionfile" ]]; then
	[ "$BUMP" != "no" ] && echo -n 1 > "$versionfile"
	build_number=1
else
	build_number=$(< "$versionfile")
	let build_number++
	if [ "$BUMP" != "no" ]; then
		echo -n "$build_number" > "$versionfile"
	fi
fi

buildno_part="-$build_number"
if [[ $SKIPONE -eq 1 && $build_number -eq 1 ]]; then
	buildno_part=""
fi

extra_part=""
if [[ ! -z "$EXTRAVERS" ]]; then
	extra_part="+$EXTRAVERS"
fi

if [[ $ONLYVERSION -eq 1 ]]; then
	echo "$version$buildno_part$extra_part"
else
	sed -e "s/^Version: \(.*\)/Version: \1$buildno_part$extra_part/g" $CONTROL
fi
