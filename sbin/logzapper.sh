#!/bin/bash
#
#  logzapper.sh  -  Clears up the Hadoop log directories
#
HADOOP_LOGDIR=
dryrun=0

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"
HADOOP_ENV_PATH="/opt/TDH/etc"

if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
elif [ -r "${HADOOP_ENV_PATH}/${HADOOP_ENV}" ]; then
    . /opt/TDH/etc/$HADOOP_ENV
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi
# -----------

if [ -z "$HADOOP_LOGDIR" ] ; then
    HADOOP_LOGDIR="/var/log/hadoop"
fi


usage="
Script to clear TDH Log Directories.

Usage: $TDH_PNAME [options]
  
  -n | --dryrun   :  Dryrun, files to be removed are listed only.
  -h | --help     :  Display usage info and exit.
  -V | --version  :  Show version info and exit.
"


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

    cd $path
    cwd=`pwd`

    echo "ERASE: $cwd"

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


while [ $# -gt 0 ]; do
    case "$1" in
        -n|--dryrun|--dry-run)
            dryrun=1
            echo "  <DRYRUN Enabled>"
            ;;
        'help'|-h|--help)
            usage
            exit 0
            ;;
        'version'|-V|--version)
            tdh_version
            exit 0
            ;;
        *)
            ;;
    esac
    shift
done


echo "
HADOOP_LOGDIR=$HADOOP_LOGDIR

Warning! This will permanently erase all files in the directory.
"

ask  "Are you sure you wish to continue? (y/N)" "N"
rt=$?

if [ $rt -eq 0 ]; then
    erase_all "$HADOOP_LOGDIR"
    rt=$?
fi

exit $rt
