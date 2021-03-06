# shellcheck shell=bash
HERE="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/common/routines.sh"

# Produces the library name used by needed_libs
library_name() {
    echo -n "$1"
}

# Produces the names of the libraries needed by the given shared libraries.
#
# The output is of the form: lib1 'needed libraries' lib2 '...' ...
# suitable for assignment of associative arrays.
#
# Requires scanelf to be on the path.
needed_libs() {
    declare -a libs=()
    # skip excluded libraries
    for lib in "$@"
    do
        if [ ! ${excluded_libs["${lib##*/}"]+defined} ]
        then
            libs+=("$lib")
        fi
    done
    scanelf -qn "${libs[@]}" | sed "s/\([^ ]*\)  \(.*\)/\\2 \\1/;y/,/ /"
}

# copy-lib FILE DEST
#
# Copies the shared library or executable to DEST.
#
copy_lib() {
    cp "$@"
}

# collect_lib_paths FILES
#
# Print the paths to dependencies needed by the given executables or shared libraries.
#
collect_lib_paths() {

    libs_str=$(ldd $(printf "%s\n" "$@" | xargs -n1 -d '\n' realpath))

    # Fail if there are any missing libraries
    if echo "$libs_str" | grep 'not found' 1>&2
    then
        exit 1
    fi

    # Collect library paths
    echo "$libs_str" \
      | grep '=>' \
      | grep -v 'linux-vdso.so' \
      | sed "s/^.* => \\(.*\\) (0x[0-9a-f]*)/\\1/" \
      | sort -u
}
