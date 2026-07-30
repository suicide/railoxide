# RailOxide development helpers.
#
# Prerequisites (run once or use nix run nixpkgs#<tool>):
#   nix profile install nixpkgs#bubblewrap

# Show all available commands.
default:
    @just --list --unsorted

# Path to the wallet binary. Override with: just run-isolated binary=./my-bin
binary := "target/release/wallet"
# Directory where isolated wallet data is stored.
data_dir := justfile_directory() / "data"

# Build the wallet release binary.
build:
    cargo build --release -p wallet

# Run the wallet in a bwrap sandbox with no access to /home, /root, or /run/user.
# The binary must already exist (run `just build` first or set binary=...).
run-isolated:
    #!/usr/bin/env bash
    set -euo pipefail
    chmod +x scripts/railoxide-isolated 2>/dev/null || true
    if [[ ! -x "{{binary}}" ]]; then
      echo "error: binary '{{binary}}' not found. Run 'just build' first or set binary=..." >&2
      exit 1
    fi
    exec env RAILOXIDE_BINARY="{{binary}}" RAILOXIDE_DATA="{{data_dir}}" scripts/railoxide-isolated

# Build the wallet debug binary.
build-debug:
    cargo build -p wallet

# Run the wallet debug binary in isolation.
run-debug:
    just binary="target/debug/wallet" run-isolated

# Build debug and run isolated in one step.
build-and-run-debug: build-debug run-debug

# Build and run isolated in one step.
build-and-run: build
    just run-isolated binary="{{binary}}"

# Wipe the isolated data directory.
clean-data:
    rm -rf {{data_dir}}

# List files stored in the isolated data directory (max depth 3).
ls-data:
    @echo "Isolated data at {{data_dir}}:"
    @if [[ -d {{data_dir}} ]]; then find {{data_dir}} -maxdepth 3 -not -path '*/\.*' | sort; else echo "  (no data yet)"; fi
