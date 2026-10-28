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

