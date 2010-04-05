#!/bin/sh

SELF=$(cd ${0%/*} && echo $PWD/${0##*/})

case "$1" in
        "init") CMD="submodule update --init" ;;
        *) CMD="$*" ;;
esac

git $CMD
git submodule foreach "$SELF" $CMD
