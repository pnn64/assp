#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash build.sh [options]

Build the native Linux ASSP standalone executable at target/assp.

Options:
  --clean, -Clean             remove target/ before building
  --profile-symbols, -ProfileSymbols
                              emit DWARF debug info and a linker map
  --phase-profile, -PhaseProfile
                              define ASSP_PHASE_PROFILE
  --run-fixture, -RunFixture  run the built executable
  --fixture, -Fixture PATH    fixture path for --run-fixture
  --chart, -Chart N           chart index for --run-fixture (default: 0)
  --list-charts, -ListCharts  pass "list" instead of a chart index
  --help, -h                  show this help

Requirements:
  nasm
  ld, cc, or gcc
EOF
}

die() {
    echo "build.sh: $*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "$1 was not found on PATH."
}

resolve_path() {
    if command -v realpath >/dev/null 2>&1; then
        realpath -m "$1"
    else
        local dir
        dir=$(dirname "$1")
        local base
        base=$(basename "$1")
        (cd "$dir" && printf '%s/%s\n' "$(pwd -P)" "$base")
    fi
}

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
target="$root/target"
exe="$target/assp"
map="$target/assp.map"
include="$root/include"

clean=0
profile_symbols=0
phase_profile=0
run_fixture=0
fixture=""
chart=0
list_charts=0

while (($#)); do
    case "$1" in
        --clean|-Clean)
            clean=1
            ;;
        --profile-symbols|-ProfileSymbols)
            profile_symbols=1
            ;;
        --phase-profile|-PhaseProfile)
            phase_profile=1
            ;;
        --run-fixture|-RunFixture)
            run_fixture=1
            ;;
        --fixture|-Fixture)
            (($# >= 2)) || die "$1 requires a path."
            fixture=$2
            shift
            ;;
        --chart|-Chart)
            (($# >= 2)) || die "$1 requires a chart index."
            chart=$2
            shift
            ;;
        --list-charts|-ListCharts)
            list_charts=1
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            die "unexpected argument: $1"
            ;;
    esac
    shift
done

require_cmd nasm

if ((clean)); then
    rm -rf "$target"
fi
mkdir -p "$target"

mapfile -d '' asm_files < <(find "$root/asm" -type f -name '*.asm' -print0 | sort -z)
((${#asm_files[@]} != 0)) || die "no NASM source files found under $root/asm."

objs=()
for asm in "${asm_files[@]}"; do
    rel=${asm#"$root/asm/"}
    obj_name=${rel//\//_}
    obj_name=${obj_name%.asm}.o
    obj="$target/$obj_name"

    nasm_args=(-f elf64 "-I$include/" -DASSP_STANDALONE_EXE -DASSP_LINUX)
    if ((profile_symbols)); then
        nasm_args+=(-g -F dwarf)
    fi
    if ((phase_profile)); then
        nasm_args+=(-DASSP_PHASE_PROFILE)
    fi
    nasm_args+=("$asm" -o "$obj")

    nasm "${nasm_args[@]}"
    objs+=("$obj")
done

if command -v ld >/dev/null 2>&1; then
    link_args=(-nostdlib -e _start -o "$exe")
    if ((profile_symbols)); then
        link_args+=("-Map=$map")
    fi
    ld "${link_args[@]}" "${objs[@]}"
elif command -v cc >/dev/null 2>&1; then
    link_args=(-nostdlib -no-pie -Wl,-e,_start -o "$exe")
    if ((profile_symbols)); then
        link_args+=("-Wl,-Map,$map")
    fi
    cc "${link_args[@]}" "${objs[@]}"
elif command -v gcc >/dev/null 2>&1; then
    link_args=(-nostdlib -no-pie -Wl,-e,_start -o "$exe")
    if ((profile_symbols)); then
        link_args+=("-Wl,-Map,$map")
    fi
    gcc "${link_args[@]}" "${objs[@]}"
else
    die "no Linux linker found. Install binutils ld, cc, or gcc."
fi

chmod +x "$exe"
echo "built $exe"

if ((run_fixture)); then
    if [[ -z "$fixture" ]]; then
        fixture="$root/fixtures/camellia_mix.ssc"
    fi
    fixture=$(resolve_path "$fixture")
    [[ -f "$fixture" ]] || die "fixture was not found: $fixture"

    run_args=("$fixture")
    if ((list_charts)); then
        run_args+=("list")
    else
        run_args+=("$chart")
    fi

    echo "running $exe ${run_args[*]}"
    (cd "$root" && "$exe" "${run_args[@]}")
fi
