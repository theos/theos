#!/bin/bash

framework_path="$1"
framework="$2"
destination_framework="$3"
fallback_framework_path="$4"

if [ -e "$framework_path/$framework" ]; then
	mkdir -p `dirname "$destination_framework"`
	exec ln -s "$framework_path/$framework" "$destination_framework"
fi

framework_name="${framework%.*}"

if [ ! -e "$fallback_framework_path/$framework/$framework_name" ]; then
	echo "Missing private framework $framework for this target. Expected private frameworks at $1"
	exit 1
fi

echo "Generating $framework/$framework_name.tbd..."

mkdir -p "$destination_framework"
# I can't YAML
(
	echo '---'
	echo 'archs: [ armv7, armv7s, arm64 ]'
	echo 'platform: ios'
	echo "install-name: /System/Library/PrivateFrameworks/$framework/$framework_name"
	echo "exports:"
	echo '  - archs: [ armv7, armv7s, arm64 ]'
	printf '    symbols: [ '
	nm -gUj "$fallback_framework_path/$framework/$framework_name" | sort | uniq | tr '\n' ',' | sed -e 's/,$/ ]/g' -e 's/,/, /g'
	echo '...'
) > "$destination_framework/$framework_name.tbd"
