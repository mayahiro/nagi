#!/bin/sh

set -eu

if [ "$#" -ne 1 ]; then
    printf '%s\n' "usage: $0 UNICODE_DATA" >&2
    exit 2
fi

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
data_dir=$(CDPATH= cd -- "$1" && pwd)
temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/nagi-unicode.XXXXXX")
trap 'rm -rf "$temporary_dir"' EXIT HUP INT TERM

cargo run --quiet --manifest-path "$root_dir/nagi-rs/Cargo.toml" -p nagi-unicode-gen -- \
    --data-dir "$data_dir" \
    --out "$temporary_dir/generated.rs" \
    --fixture-out "$temporary_dir/rust-fixture.txt"

(
    cd "$root_dir/nagi-go"
    GOTOOLCHAIN=local go run ./cmd/unicodegen \
        -data-dir "$data_dir" \
        -out "$temporary_dir/generated.go" \
        -fixture-out "$temporary_dir/go-fixture.txt"
)

cmp "$temporary_dir/generated.rs" "$root_dir/nagi-rs/crates/nagi-text/src/generated.rs"
cmp "$temporary_dir/generated.go" "$root_dir/nagi-go/text/generated.go"
cmp "$temporary_dir/rust-fixture.txt" "$root_dir/fixtures/text/grapheme-break-17.0.0.txt"
cmp "$temporary_dir/go-fixture.txt" "$root_dir/fixtures/text/grapheme-break-17.0.0.txt"

printf '%s\n' "Unicode 17.0.0 generated files are deterministic and current"
