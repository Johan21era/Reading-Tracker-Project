#!/bin/bash
# astera — stable terminal entry point for the absolute latest Asterisma tree.
#
# Installed by scripts/astera-bootstrap.sh as ~/.local/bin/astera. The
# bootstrap locates the repository (config, current directory, then a scan),
# while this script owns the update policy so it is versioned with the project.
#
#   astera              fast-forward from origin when clean, build, and launch
#   astera --build-only fast-forward when clean, then build without launching
#   astera --help       show run-latest.sh usage (never pulls)
#
# Set ASTERA_NO_PULL=1 to build the local tree without contacting origin.
set -euo pipefail

SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done

ROOT="$(cd -P "$(dirname "$SOURCE")/.." >/dev/null 2>&1 && pwd)"

if [[ ! -x "$ROOT/scripts/run-latest.sh" ]]; then
    echo "astera: no runnable scripts/run-latest.sh under $ROOT" >&2
    exit 1
fi

needs_pull=1
case "${1:-}" in
    -h|--help) needs_pull=0 ;;
esac
[[ "${ASTERA_NO_PULL:-0}" == "1" ]] && needs_pull=0

if [[ "$needs_pull" == "1" ]] && command -v git >/dev/null 2>&1; then
    if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        branch="$(git -C "$ROOT" symbolic-ref --short -q HEAD || true)"
        upstream="$(git -C "$ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"

        if [[ -z "$branch" || -z "$upstream" ]]; then
            echo "astera: no upstream branch; building the local tree."
        elif [[ -n "$(git -C "$ROOT" status --porcelain --untracked-files=no)" ]]; then
            echo "astera: tracked local changes present; building the local tree without pulling."
        elif ! git -C "$ROOT" fetch --quiet origin; then
            echo "astera: could not reach origin; building the local tree."
        elif [[ "$(git -C "$ROOT" rev-parse HEAD)" == "$(git -C "$ROOT" rev-parse "$upstream")" ]]; then
            : # already at the absolute latest
        elif git -C "$ROOT" merge-base --is-ancestor HEAD "$upstream"; then
            echo "astera: fast-forwarding $branch from $upstream…"
            if ! git -C "$ROOT" merge --ff-only --quiet "$upstream"; then
                echo "astera: fast-forward failed; building the local tree."
            fi
        else
            echo "astera: local branch has commits that are not on $upstream; building the local tree."
        fi
    fi
fi

exec "$ROOT/scripts/run-latest.sh" "$@"
