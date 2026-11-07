#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

run_target() {
  local kind="$1"
  local target_var="$2"
  local name="$3"
  local source="$4"
  local include="$5"
  local dir="$tmp/$kind"
  mkdir -p "$dir"
  printf 'int main(void) { return 0; }\n' > "$dir/$source"
  cat > "$dir/Makefile" <<EOF
TARGET := iphone:clang:latest:13.0
ARCHS := arm64
include \$(THEOS)/makefiles/common.mk
${target_var} := $name
${name}_FILES := $source
include \$(THEOS_MAKE_PATH)/$include
EOF
  if [[ "$kind" == tweak ]]; then
    printf '{ Filter = { Bundles = ( "com.apple.springboard" ); }; }\n' > "$dir/$name.plist"
    cat > "$dir/control" <<EOF
Package: org.theos.$name
Name: $name
Version: 1.0
Architecture: iphoneos-arm64
Description: POSIX Makefile graph smoke
EOF
  fi
  local args=("THEOS=$root" "THEOS_SDKS_PATH=$THEOS_SDKS_PATH" "SYSROOT=$THEOS_SDKROOT" "ISYSROOT=$THEOS_SDKROOT")
  if [[ "$(uname -s)" == Linux ]]; then args+=("SDKBINPATH=${SDKBINPATH:?}"); fi
  make -C "$dir" --no-print-directory -n all "${args[@]}" >/dev/null
  printf 'PASS: %s Makefile graph parsed\n' "$kind"
}

run_target tool TOOL_NAME posix_tool main.c tool.mk
run_target tweak TWEAK_NAME posix_tweak Tweak.m tweak.mk
run_target library LIBRARY_NAME posix_library library.c library.mk
run_target framework FRAMEWORK_NAME PosixFramework framework.c framework.mk
