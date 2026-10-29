#!/bin/bash
# astera-bootstrap.sh — the stable `astera` command installed on PATH.
#
# This file is copied to ~/.local/bin/astera by:
#   cp scripts/astera-bootstrap.sh ~/.local/bin/astera
#   chmod +x ~/.local/bin/astera
#
# It deliberately contains no build logic. It finds the newest Asterisma
# checkout (cached config, current directory, then common project roots),
# records that location in ~/.config/astera/root, and execs the repository's
# own scripts/astera.sh. Moving or renaming the checkout therefore does not
# break the command: the cached path is validated, then rediscovered.
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/astera"
CONFIG="$CONFIG_DIR/root"

is_root() {
    local dir="${1:-}"
    [[ -n "$dir" && -d "$dir" && -x "$dir/scripts/astera.sh" ]] || return 1
    compgen -G "$dir/AsterismaV*.xcodeproj" >/dev/null
}

version_for() {
    local root="$1" best="" project name
    for project in "$root"/AsterismaV*.xcodeproj; do
        [[ -d "$project" ]] || continue
        name="${project##*/}"
        name="${name%.xcodeproj}"
        if [[ -z "$best" || "$(printf '%s\n%s\n' "$best" "$name" | sort -V | tail -1)" == "$name" ]]; then
            best="$name"
        fi
    done
    printf '%s' "$best"
}

CANDIDATES=()
add_candidate() {
    local candidate="$1" existing
    is_root "$candidate" || return 0
    candidate="$(cd -P "$candidate" && pwd)"
    for existing in "${CANDIDATES[@]:-}"; do
        [[ "$existing" == "$candidate" ]] && return 0
    done
    CANDIDATES+=("$candidate")
}

ROOT=""

# 1. Explicit override.
if [[ -n "${ASTERISMA_ROOT:-}" ]] && is_root "$ASTERISMA_ROOT"; then
    ROOT="$(cd -P "$ASTERISMA_ROOT" && pwd)"
fi

# 2. Last known location, validated before use.
if [[ -z "$ROOT" && -f "$CONFIG" ]]; then
    cached="$(head -n 1 "$CONFIG" 2>/dev/null || true)"
    if is_root "$cached"; then
        ROOT="$(cd -P "$cached" && pwd)"
    fi
fi

# 3. The checkout the caller is standing in (including subdirectories).
if [[ -z "$ROOT" ]]; then
    probe="$PWD"
    while :; do
        add_candidate "$probe"
        [[ "$probe" == "/" ]] && break
        probe="$(dirname "$probe")"
    done
fi

# 4. Common project roots, plus a shallow home scan for a moved checkout.
if [[ -z "$ROOT" && ${#CANDIDATES[@]} -eq 0 ]]; then
    scan() {
        local base="$1" depth="$2" project
        [[ -d "$base" ]] || return 0
        while IFS= read -r -d '' project; do
            add_candidate "$(dirname "$project")"
        done < <(find "$base" -maxdepth "$depth" -type d -name 'AsterismaV*.xcodeproj' -print0 2>/dev/null)
    }
    for base in "$HOME/Desktop" "$HOME/Documents" "$HOME/Developer" "$HOME/Projects" "$HOME/Code" "$HOME/src"; do
        scan "$base" 4
    done
    scan "$HOME" 2
fi

if [[ -z "$ROOT" ]]; then
    [[ ${#CANDIDATES[@]} -gt 0 ]] || {
        echo "astera: could not find an Asterisma checkout." >&2
        echo "astera: set ASTERISMA_ROOT=/path/to/Asterisma or add ~/.config/astera/root" >&2
        exit 1
    }

    # Prefer the highest AsterismaV version; tie-break on the newest checkout.
    best_version=""
    best_mtime=-1
    for candidate in "${CANDIDATES[@]}"; do
        version="$(version_for "$candidate")"
        mtime="$(stat -f %m "$candidate" 2>/dev/null || stat -c %Y "$candidate" 2>/dev/null || echo 0)"
        if [[ -z "$ROOT" ]]; then
            :
        elif [[ "$version" == "$best_version" ]]; then
            [[ "$mtime" -le "$best_mtime" ]] && continue
        elif [[ "$(printf '%s\n%s\n' "$best_version" "$version" | sort -V | tail -1)" != "$version" ]]; then
            continue
        fi
        ROOT="$candidate"
        best_version="$version"
        best_mtime="$mtime"
    done
fi

if [[ -z "$ROOT" ]]; then
    echo "astera: found candidate checkouts but none were usable." >&2
    exit 1
fi

mkdir -p "$CONFIG_DIR"
printf '%s\n' "$ROOT" > "$CONFIG"

exec "$ROOT/scripts/astera.sh" "$@"
