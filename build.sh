#!/bin/sh
set -eu

usage() {
    cat <<'EOF'
Usage: sh build.sh [options]

Build the native Linux or FreeBSD ASSP standalone executable at target/assp.
The target OS is auto-detected from uname unless --target is supplied.

Options:
  --target, -Target OS        target OS: linux or freebsd
  --clean, -Clean             remove target/ before building
  --profile-symbols, -ProfileSymbols
                              emit DWARF debug info and a linker map
  --phase-profile, -PhaseProfile
                              define ASSP_PHASE_PROFILE
  --startup-trace, -StartupTrace
                              define ASSP_STARTUP_TRACE for platform shim logs
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

detect_host_target() {
    case "$(uname -s 2>/dev/null || true)" in
        Linux)
            echo linux
            ;;
        FreeBSD)
            echo freebsd
            ;;
        *)
            echo unknown
            ;;
    esac
}

resolve_path() {
    case "$1" in
        /*)
            path=$1
            ;;
        *)
            path=$(pwd -P)/$1
            ;;
    esac

    dir=$(dirname "$path")
    base=$(basename "$path")
    (cd "$dir" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$base")
}

assemble_one() {
    (
        asm=$1
        obj=$2

        set -- -f elf64 "-I$include/" -DASSP_STANDALONE_EXE "$target_define"
        if [ "$profile_symbols" -eq 1 ]; then
            set -- "$@" -g -F dwarf
        fi
        if [ "$phase_profile" -eq 1 ]; then
            set -- "$@" -DASSP_PHASE_PROFILE
        fi
        if [ "$startup_trace" -eq 1 ]; then
            set -- "$@" -DASSP_STARTUP_TRACE
        fi
        set -- "$@" "$asm" -o "$obj"

        nasm "$@"
    )
}

link_with_ld() {
    set -- -static -e _start -o "$exe" "$@"
    if [ "$profile_symbols" -eq 1 ]; then
        set -- "-Map=$map" "$@"
    fi

    ld "$@"
}

link_with_cc() {
    compiler=$1
    shift

    set -- -static -nostdlib -no-pie -Wl,-e,_start -o "$exe" "$@"
    if [ "$profile_symbols" -eq 1 ]; then
        set -- "-Wl,-Map,$map" "$@"
    fi

    "$compiler" "$@"
}

root=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
target="$root/target"
exe="$target/assp"
map="$target/assp.map"
include="$root/include"
source_list="$target/asm_sources.list"

host_target=$(detect_host_target)
target_os=
clean=0
profile_symbols=0
phase_profile=0
startup_trace=0
run_fixture=0
fixture=
chart=0
list_charts=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --target|-Target)
            [ "$#" -ge 2 ] || die "$1 requires linux or freebsd."
            target_os=$2
            shift
            ;;
        --clean|-Clean)
            clean=1
            ;;
        --profile-symbols|-ProfileSymbols)
            profile_symbols=1
            ;;
        --phase-profile|-PhaseProfile)
            phase_profile=1
            ;;
        --startup-trace|-StartupTrace)
            startup_trace=1
            ;;
        --run-fixture|-RunFixture)
            run_fixture=1
            ;;
        --fixture|-Fixture)
            [ "$#" -ge 2 ] || die "$1 requires a path."
            fixture=$2
            shift
            ;;
        --chart|-Chart)
            [ "$#" -ge 2 ] || die "$1 requires a chart index."
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

if [ -z "$target_os" ]; then
    target_os=$host_target
fi

case "$target_os" in
    linux)
        target_define=-DASSP_LINUX
        ;;
    freebsd)
        target_define=-DASSP_FREEBSD
        ;;
    *)
        die "unsupported target OS: $target_os. Use --target linux or --target freebsd."
        ;;
esac

require_cmd nasm

if [ "$clean" -eq 1 ]; then
    rm -rf "$target"
fi
mkdir -p "$target"

find "$root/asm" -type f -name '*.asm' | sort > "$source_list"
[ -s "$source_list" ] || die "no NASM source files found under $root/asm."

set --
while IFS= read -r asm; do
    rel=${asm#"$root/asm/"}
    obj_name=$(printf '%s\n' "$rel" | sed 's|/|_|g; s|\.asm$|.o|')
    obj="$target/$obj_name"

    assemble_one "$asm" "$obj"
    set -- "$@" "$obj"
done < "$source_list"

if command -v ld >/dev/null 2>&1; then
    link_with_ld "$@"
elif command -v cc >/dev/null 2>&1; then
    link_with_cc cc "$@"
elif command -v gcc >/dev/null 2>&1; then
    link_with_cc gcc "$@"
else
    die "no linker found. Install binutils ld, cc, or gcc."
fi

chmod +x "$exe"
echo "built $exe ($target_os)"

if [ "$run_fixture" -eq 1 ]; then
    if [ "$host_target" != "$target_os" ]; then
        die "cannot run a $target_os executable on this $host_target host."
    fi

    if [ -z "$fixture" ]; then
        fixture="$root/fixtures/camellia_mix.ssc"
    fi
    fixture=$(resolve_path "$fixture") || die "could not resolve fixture path: $fixture"
    [ -f "$fixture" ] || die "fixture was not found: $fixture"

    if [ "$list_charts" -eq 1 ]; then
        echo "running $exe $fixture list"
        (cd "$root" && "$exe" "$fixture" list)
    else
        echo "running $exe $fixture $chart"
        (cd "$root" && "$exe" "$fixture" "$chart")
    fi
fi
