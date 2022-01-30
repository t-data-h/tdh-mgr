#!/bin/bash
#
#  logzapper.sh  -  Clears up the Hadoop log directories
#
HADOOP_LOGDIR=
dryrun=0
prompt=0

# ----------- preamble
HADOOP_ENV="tdh-env.sh"
HADOOP_ENV_PATH="/opt/TDH/etc"

if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
elif [ -r "${HADOOP_ENV_PATH}/${HADOOP_ENV}" ]; then
    . /opt/TDH/etc/$HADOOP_ENV
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'" >&2
    exit 1
fi

HADOOP_LOG_DIR=${HADOOP_LOG_DIR:-/var/log/tdh}

# -----------

usage="
Script to clear TDH Log Directories.

Usage: $TDH_PNAME [options]
  
  -n | --dryrun   :  Dryrun, files to be removed are listed only.
  -h | --help     :  Display usage info and exit.
  -P | --noprompt :  Don't ask for approval. 
                     This removes logs without prompting!
  -V | --version  :  Show version info and exit.
"

# -----------

ask()
{
    local prompt="y/n"
    local default=
    local REPLY=

    while true; do
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        fi

        read -p "$1 [$prompt] " REPLY

        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi

        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}


# recursive rm of all files and directories save for
# the top level directories in HADOOP_LOGDIR
erase_all()
{
    local path="$1"
    local rec="$2"  # recurse
    local rt=0
    local cwd=

    if [[ -z "$path" || ! -d $path ]]; then
        echo "Path provided is not valid: '$path'" >&2
        return 1
    fi

    cd $path
    if [ $? -ne 0 ]; then
        echo "Error in cd to path: '$path'" >&2
        return 1
    fi

    cwd=$(pwd)
    echo "ERASE: $cwd"
    if [ $prompt -eq 0 ]; then
        ask  "Are you sure you wish to continue? (y/N)" "N"
        rt=$?
    fi

    for x in *
    do
        if [ -d $x ]; then
            if [ -z "$rec" ]; then
                erase_all $x 1
            else
                echo "  rm -r $x"
                if [ $dryrun -eq 0 ]; then
                    $(rm -rf "$x")
                    rt=$?
                fi
            fi
            cd $cwd
            if [ $? -ne 0 ]; then
                echo "Error in 'cd', aborting.." >&2
                break
            fi
        elif [ -f $x ]; then
            echo "  rm $cwd/$x"
            if [ $dryrun -eq 0 ]; then
                $(rm "$cwd/$x")
                rt=$?
            fi
        fi
    done

    return $rt
}

# -------------------
# MAIN
rt=0

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dryrun|--dry-run)
            dryrun=1
            echo "  <DRYRUN Enabled>"
            ;;
        'help'|-h|--help)
            usage
            exit $rt
            ;;
        -P|--noprompt|--no-prompt)
            prompt=1
            ;;
        'version'|-V|--version)
            tdh_version
            exit $rt
            ;;
        *)
            ;;
    esac
    shift
done


echo "
HADOOP_LOG_DIR=$HADOOP_LOG_DIR

Warning! This will permanently erase all files in the directory.
"

if [ -z "$HADOOP_LOG_DIR" ]; then
    echo "Error, HADOOP_LOG_DIR not set" >&2
    exit 1
fi

cd $HADOOP_LOG_DIR
if [ $? -ne 0 ]; then 
    echo "Error in path HADOOP_LOG_DIR=$HADOOP_LOG_DIR"
    exit 1
fi

if [ $rt -eq 0 ]; then
    erase_all "$HADOOP_LOG_DIR"
    rt=$?
fi

exit $rt
