#!/bin/sh

case "$1" in
        "init") CMD="submodule update --init" ;;
        *) CMD="$*" ;;
esac

git $CMD
git submodule foreach "$0" $CMD
