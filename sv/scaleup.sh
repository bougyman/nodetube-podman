#!/bin/bash
me=${BASH_SOURCE[0]}
# Resolve if we are a symlink
real_me=$(readlink -f "$me")
# Set $real_here to the full actual path to this script
real_here=$(dirname "${real_me}")
# Set $here to the full path to this script (if it's a symlink, the symlink path will be here)
here=$(cd "$(dirname "$me")" && pwd)
# Just the directory name
here_dir=$(basename "$here")

usage() { # {{{
    cat <<-EOT
    Usage: $0 <options> APPNAME
        Options:
            -g NAME       The name of the generic app you are tying to scale (Default: Same as APPNAME)
            -n NUM        Scale up by NUM (Default: 1) 
            -h            Show help / usage

    APPNAME will be the base name(s) of the new service directories.
EOT
} # }}}

die() { # {{{
  local -i code
    code=$1
    shift
    echo "Error! => $*" >&2
    echo >&2
    usage >&2
    # shellcheck disable=SC2086
    exit $code
} # }}}

while getopts :hn:g: opt # {{{
do
    case $opt in
        n)
            NUM=${OPTARG}
            ;;
        g)
            GENERIC_NAME=${OPTARG}
            ;;
        h)
            usage
            exit
            ;;
        \?)
            echo "Invalid option '${OPTARG}'" >&2
            usage >&2
            exit 27
            ;;
        :)
            echo "Option ${OPTARG} requires an argument" >&2
            usage >&2
            exit 28
            ;;
    esac
done # }}}
shift $((OPTIND-1))

app_name=$1
[ -z "$app_name" ] && die 1 "You must supply an APPNAME as an argument"

: "${GENERIC_NAME:=$app_name}"
: "${NUM:=1}"

scale_up() {
    local generic_service nextup
    generic_service=$1
    nextup=$2
    service_name=${generic_service%-*}
    just_service=${service_name#*-}
    if [ "$just_service" = "$GENERIC_NAME" ]
    then
        next_service="${app_name}-$nextup"
    else
        next_service="${app_name}-${just_service}-$nextup"
    fi
    [ -d "${next_service}" ] && continue
    mkdir "${next_service}"
    pushd "${next_service}"
    ln -vs "$real_here/${generic_service}/run"
    [ -d log ] || mkdir log
    pushd log
    ln -vs "$real_here/${generic_service}/log/run"
    popd
    popd
}

for i in $(seq 1 "$NUM")
do
    highest=$(ls -d "${app_name}"-[0-9][0-9] 2>/dev/null | awk -F- '{print $2}' | tail -1)
    [ -z "$highest" ] && highest=0
    nextnum=$(printf "%d" "$((highest + 1))")
    nextnum=$(printf "%02d\n" "$nextnum")
    scale_up "${GENERIC_NAME}-generic" "$nextnum"
    cp -a "${GENERIC_NAME}"-generic/env "${app_name}-${nextnum}/"
    for service in $(ls -d -- "${GENERIC_NAME}"-*-generic)
    do
        scale_up "$service" "$nextnum"
    done
    echo $i
done

# vim: set foldmethod=marker et ts=4 sts=4 sw=4 :
