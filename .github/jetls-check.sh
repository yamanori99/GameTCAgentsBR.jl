#!/usr/bin/env bash
# Entry files for `jetls check` (hint+). JETLS follows top-level `include()`.
#
# ./.github/jetls-check.sh
# ./.github/jetls-check.sh --progress=none
# ./.github/jetls-check.sh --print-files
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
shopt -s nullglob

# demo/ and test/ have their own projects (UnicodePlots, Test).
# One --root would load only the package env.
files_pkg=(
    src/GameTCAgentsBR.jl
)
# Paths are relative to each --root.
files_demo=(
    run.jl
)
files_test=(
    runtests.jl
)

print_files=false
jetls_args=()
for arg in "$@"; do
    if [[ "$arg" == "--print-files" ]]; then
        print_files=true
    else
        jetls_args+=("$arg")
    fi
done

if [[ "$print_files" == true ]]; then
    printf '%s\n' "${files_pkg[@]}" "demo/${files_demo[@]}" "test/${files_test[@]}"
    exit 0
fi

# Pkg Apps shims pin a Julia binary. juliaup upgrades leave that path missing.
# The shim honors JULIA_APPS_JULIA_CMD; default to PATH `julia`.
if [[ -z "${JULIA_APPS_JULIA_CMD:-}" ]]; then
    export JULIA_APPS_JULIA_CMD="$(command -v julia)"
fi

# Match DistSSHKit / aviatesk/JETLS.jl check@release: do not pass `--threads=auto`.
jetls check --root=. --exit-severity=hint "${jetls_args[@]}" "${files_pkg[@]}"
jetls check --root=demo --exit-severity=hint "${jetls_args[@]}" "${files_demo[@]}"
jetls check --root=test --exit-severity=hint "${jetls_args[@]}" "${files_test[@]}"
