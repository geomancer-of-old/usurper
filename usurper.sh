#! /usr/bin/env bash
# Author: geomancer-of-old (Khahliso)
# Purpose: Lab lifecycle manager

set -euo pipefail

# -- configurations --
USURPER_HOME="${USURPER_HOME:-/opt/usurper}"
LABS_DIR="$USURPER_HOME/labs"
LABS_DIR="$(readlink -f "$LABS_DIR" 2>/dev/null || echo "$LABS_DIR")"
REGISTRY="$LABS_DIR/registry"          # one lab name per line; '#' comments ok
STATE_DIR="/var/lib/usurper"           
STATE_FILE="$STATE_DIR/active"
LOCK_FILE="$STATE_DIR/lock"

NAME_RE='^[a-z0-9][a-z0-9_-]*$'  # lab name whitelist

# -- helper functions --

die() { printf 'usurper: %s\n' "$*" >&2; exit 1; }
info() { printf '%s\n' "$*"; }

require_root() {
    [[ ${EUID:-$(id -u)} -eq 0 ]] || die "must be run as root (use sudo)"
}

valid_name() {
    [[ "$1" =~ $NAME_RE ]] || die "invalid lab name: '$1'"
}

registered_labs() {
    [[ -f "$REGISTRY" ]] || die "no lab registry at $REGISTRY"
    grep -vE '^[[:space:]]*(#|$)' "$REGISTRY" || true
}

lab_is_registered() {
    grep -qxF "$1" <(registered_labs)
}

active_lab() {
    [[ -s "$STATE_FILE" ]] && cat "$STATE_FILE" || true
}

# resolve + confine a lab's phase script inside LABS_DIR
lab_script() {
    local lab="$1" phase="$2"
    local path="$LABS_DIR/$lab/$phase.sh"
    local real; real="$(readlink -f "$path" 2>/dev/null || true)"
    [[ -n "$real" && "$real" == "$LABS_DIR/"* ]] || die "path escapes labs dir: $path"
    [[ -f "$real" ]] || die "missing $phase script for '$lab' ($path)"
    printf '%s\n' "$real"
}