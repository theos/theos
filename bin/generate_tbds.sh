#!/bin/bash

for framework in `ls "$1"`; do
	framework_name="${framework%.*}"
	echo "Generating $framework/$framework_name.tbd"
	mkdir -p "$2/$framework"
	# I can't YAML
	(
		echo '---'
		echo 'archs: [ armv7, armv7s, arm64 ]'
		echo 'platform: ios'
		echo "install-name: /System/Library/PrivateFrameworks/$framework/$framework_name"
		echo "exports:"
		echo '  - archs: [ armv7, armv7s, arm64 ]'
		printf '    symbols: [ '
		nm -gUj "$1/$framework/$framework_name" | sort | uniq | tr '\n' ',' | sed -e 's/,$/ ]/g' -e 's/,/, /g'
		echo '...'
	) > "$2/$framework/$framework_name.tbd"
done
