#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash build.sh [options]

Build the current ASSP standalone executable from a Linux host. The standalone
app is still Win64/Win32-API assembly, so this script cross-builds target/assp.exe.

Options:
  --clean, -Clean             remove target/ before building
  --profile-symbols, -ProfileSymbols
                              emit NASM debug info and linker map/PDB when supported
  --phase-profile, -PhaseProfile
                              define ASSP_PHASE_PROFILE
  --run-fixture, -RunFixture  run the built exe under wine
  --fixture, -Fixture PATH    fixture path for --run-fixture
  --chart, -Chart N           chart index for --run-fixture (default: 0)
  --list-charts, -ListCharts  pass "list" instead of a chart index
  --help, -h                  show this help

Requirements:
  nasm
  x86_64-w64-mingw32-gcc, or lld-link/ld.lld/lld plus a MinGW-w64 kernel32 import lib
  wine only when using --run-fixture
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

find_kernel32_lib() {
    local dirs=()
    [[ -n "${MINGW_PREFIX:-}" ]] && dirs+=("$MINGW_PREFIX/lib" "$MINGW_PREFIX/x86_64-w64-mingw32/lib")
    dirs+=(
        "/usr/x86_64-w64-mingw32/lib"
        "/usr/local/x86_64-w64-mingw32/lib"
        "/usr/lib/gcc/x86_64-w64-mingw32"
        "/usr/lib64/gcc/x86_64-w64-mingw32"
        "/usr/lib/mingw-w64"
        "/usr/lib64/mingw-w64"
    )

    local dir
    for dir in "${dirs[@]}"; do
        [[ -d "$dir" ]] || continue
        local found
        found=$(find "$dir" -maxdepth 4 -type f \( -iname 'kernel32.lib' -o -iname 'libkernel32.a' \) 2>/dev/null | head -n 1 || true)
        if [[ -n "$found" ]]; then
            printf '%s\n' "$found"
            return 0
        fi
    done

    return 1
}

root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
target="$root/target"
exe="$target/assp.exe"
pdb="$target/assp.pdb"
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
    obj_name=${obj_name%.asm}.obj
    obj="$target/$obj_name"

    nasm_args=(-f win64 "-I$include/" -DASSP_STANDALONE_EXE)
    if ((profile_symbols)); then
        nasm_args+=(-g -F cv8)
    fi
    if ((phase_profile)); then
        nasm_args+=(-DASSP_PHASE_PROFILE)
    fi
    nasm_args+=("$asm" -o "$obj")

    nasm "${nasm_args[@]}"
    objs+=("$obj")
done

if command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
    link_args=(-nostdlib -Wl,-e,start -Wl,--subsystem,console -o "$exe")
    if ((profile_symbols)); then
        link_args+=("-Wl,-Map,$map")
    fi
    x86_64-w64-mingw32-gcc "${link_args[@]}" "${objs[@]}" -lkernel32
elif command -v lld-link >/dev/null 2>&1; then
    kernel32=$(find_kernel32_lib) || die "kernel32 import library was not found. Install mingw-w64 or use x86_64-w64-mingw32-gcc."
    link_args=(/nologo /machine:x64 /subsystem:console /entry:start /nodefaultlib "/out:$exe" "${objs[@]}" "$kernel32")
    if ((profile_symbols)); then
        link_args+=(/debug "/pdb:$pdb" "/map:$map" /mapinfo:exports)
    fi
    lld-link "${link_args[@]}"
elif command -v ld.lld >/dev/null 2>&1; then
    kernel32=$(find_kernel32_lib) || die "kernel32 import library was not found. Install mingw-w64 or use x86_64-w64-mingw32-gcc."
    link_args=(-flavor link /nologo /machine:x64 /subsystem:console /entry:start /nodefaultlib "/out:$exe" "${objs[@]}" "$kernel32")
    if ((profile_symbols)); then
        link_args+=(/debug "/pdb:$pdb" "/map:$map" /mapinfo:exports)
    fi
    ld.lld "${link_args[@]}"
elif command -v lld >/dev/null 2>&1; then
    kernel32=$(find_kernel32_lib) || die "kernel32 import library was not found. Install mingw-w64 or use x86_64-w64-mingw32-gcc."
    link_args=(-flavor link /nologo /machine:x64 /subsystem:console /entry:start /nodefaultlib "/out:$exe" "${objs[@]}" "$kernel32")
    if ((profile_symbols)); then
        link_args+=(/debug "/pdb:$pdb" "/map:$map" /mapinfo:exports)
    fi
    lld "${link_args[@]}"
else
    die "no Win64 linker found. Install x86_64-w64-mingw32-gcc or LLVM lld."
fi

echo "built $exe"

if ((run_fixture)); then
    require_cmd wine
    if [[ -z "$fixture" ]]; then
        fixture="$root/fixtures/camellia_mix.ssc"
    fi
    fixture=$(resolve_path "$fixture")
    [[ -f "$fixture" ]] || die "fixture was not found: $fixture"

    run_fixture_path=$fixture
    if command -v winepath >/dev/null 2>&1; then
        run_fixture_path=$(winepath -w "$fixture")
    fi

    run_args=("$run_fixture_path")
    if ((list_charts)); then
        run_args+=("list")
    else
        run_args+=("$chart")
    fi

    echo "running wine $exe ${run_args[*]}"
    (cd "$root" && wine "$exe" "${run_args[@]}")
fi
