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
    [[ "$1" =~ $NAME_RE ]] || die "[!!] Invalid lab name: '$1'"
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

## -- commands --

cmd_list() {
    local active; active="$(active_lab)"
    local any=0 lab
    while IFS= read -r lab; do
        any=1
        if [[ "$lab" == "$active" ]]; then
            printf '  * %s (active)\n' "$lab"
        else
            printf '    %s\n' "$lab"
        fi
    done < <(registered_labs)
    [[ $any -eq 1 ]] || info "[!!] No labs available"
}

cmd_check() {
    local active; active="$(active_lab)"
    [[ -n "$active" ]] && info "$active" || info "[!!] No active lab"
}

cmd_install() {
    local lab="${1:-}"; [[ -n "$lab" ]] || die "usage: usurper install <lab>"
    valid_name "$lab"
    lab_is_registered "$lab" || die "unknown lab: '$lab' (try: usurper list)"

    local active; active="$(active_lab)"
    if [[ -n "$active" ]]; then
        [[ "$active" == "$lab" ]] \
            && die "'$lab' is already active" \
            || die "'$active' is active; remove it first (usurper remove $active)"
    fi

    local script; script="$(lab_script "$lab" install)"
    info "installing '$lab'..."
    if bash "$script"; then
        printf '%s\n' "$lab" > "$STATE_FILE"   # mark active ONLY on success
        info "'$lab' is now active"
    else
        die "install script failed — '$lab' NOT marked active"
    fi
}

cmd_remove() {
    local lab="${1:-}"; [[ -n "$lab" ]] || die "usage: usurper remove <lab>"
    valid_name "$lab"

    local active; active="$(active_lab)"
    [[ -n "$active" ]] || die "no active lab to remove"
    [[ "$active" == "$lab" ]] || die "'$lab' is not active ('$active' is)"

    local script; script="$(lab_script "$lab" remove)"
    info "removing '$lab'..."
    if bash "$script"; then
        rm -f "$STATE_FILE"
        info "'$lab' removed"
    else
        die "remove script failed — '$lab' left active; fix and retry"
    fi
}



# --- entrypoint -----------------------------------------------------------
main() {
    require_root
    mkdir -p "$STATE_DIR"; chmod 0755 "$STATE_DIR"

    local cmd="${1:-}"; shift || true
    case "$cmd" in
        install|remove)
            # serialize state-changing ops against a second sudo invocation
            exec 9>"$LOCK_FILE"
            flock -n 9 || die "another usurper instance is running"
            "cmd_$cmd" "$@"
            ;;
        list)  cmd_list  "$@" ;;
        check) cmd_check "$@" ;;
        ''|-h|--help|help)
            cat <<'EOF'
            usurper : lab lifecycle manager

            usurper list              list available labs (active one marked *)
            usurper install <lab>     install and activate a lab
            usurper check             show the active lab
            usurper remove <lab>      tear down and deactivate the active lab

            Only one lab may be active at a time. Run with sudo.
EOF
            ;;
        *) die "unknown command: '$cmd' (try: usurper help)" ;;
    esac
}


main "$@"