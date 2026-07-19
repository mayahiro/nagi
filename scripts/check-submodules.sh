#!/bin/sh

set -eu

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
failed=0

cd "$root_dir"

for path in nagi-go nagi-rs nagicli-go nagitui-go; do
    status=$(git submodule status -- "$path")
    case "$status" in
        " "*) ;;
        -*)
            printf '%s\n' "Submodule $path is not initialized" >&2
            failed=1
            ;;
        +*)
            printf '%s\n' "Submodule $path is not at the revision pinned by nagi" >&2
            failed=1
            ;;
        U*)
            printf '%s\n' "Submodule $path has unresolved merge conflicts" >&2
            failed=1
            ;;
        *)
            printf '%s\n' "Unable to determine submodule state for $path" >&2
            failed=1
            ;;
    esac
done

if [ "$failed" -ne 0 ]; then
    exit 1
fi

printf '%s\n' "Submodule check passed"
