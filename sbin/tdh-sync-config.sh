#!/usr/bin/env bash
#
# tdh-sync-config.sh
#
confdir=
syncto=1
dryrun=1
delete=0

components=()

# ----------- preamble

HADOOP_ENV="tdh-env.sh"
HADOOP_ENV_PATH="/opt/TDH/etc"

if [ -r "./etc/${HADOOP_ENV}" ]; then
    . ./etc/$HADOOP_ENV
    HADOOP_ENV_PATH="./etc"
elif [ -r "/etc/hadoop/${HADOOP_ENV}" ]; then
    . /etc/hadoop/$HADOOP_ENV
    HADOOP_ENV_PATH="/etc/hadoop"
elif [ -r "${HADOOP_ENV_PATH}/${HADOOP_ENV}" ]; then
    . $HADOOP_ENV_PATH/$HADOOP_ENV
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'" >&2
    exit 1
fi

# default init list
# add 'mysqld-tdh-init.sh' for a local docker instance of mysql
INITS="hadoop-init.sh zookeeper-init.sh hbase-init.sh hive-init.sh \
kafka-init.sh spark-history-init.sh"

if [ -n "$TDH_ECOSYSTEM_INITS" ]; then
    INITS="$TDH_ECOSYSTEM_INITS"
fi

TDH_HOME="${TDH_HOME:-/opt/TDH}"

# -----------

usage="
Syncronized the cluster configuration from a configuration repo
to the current environment ie. TDH_HOME. Optionally can reverse 
direction and '--sync-from' the environment back to the config repo.

Synopsis:
  $TDH_PNAME [-hSqV] [config_path]

Options:
  -h|--help       : Show usage info and exit.
  -n|--dryrun     : Enable rsync dryrun
  -q|--quiet      : Do not prompt for approval
  -S|--sync-from  : Reverse sync from env to repo
  -V|--version    : Show version info and exit

  [config_path ]  : Path to the tdh config rep including the 
                    environment specific subpath. 
                    eg. '/home/user/src/tdh-config/myenv'
"

# -----------

function mapComponents()
{
    for c in ${INITS}; do
        cpath="$(realpath ${TDH_HOME}/${c%%-*})"
        if [ -n $cpath ]; then
            components+=("${cpath%%\/*}")
        fi
    done
}


# -----------
# Main

while [ $# -gt 0 ]; then
    case "$1" in 
    'help'|-h|--help)
        echo "$TDH_PNAME [options] [config_path_envname]"
        echo "  default is sync-to \$TDH_HOME"
        echo "  -S or --sync-from will reverse and sync from" 
        echo "  the environment to the config repo"
        exit 0
        ;;
    -n|--dryrun|--dry-run)
        dryrun=1
        ;;
    -q|--quiet)
        quiet=1
        ;;
    -S|--syncfrom|--sync-from)
        syncto=0
        ;;
    'version'|-V|--version)
        tdh_version
        exit 0
        ;;
    *)
        confdir="$1"
        shift $#
        ;;
    esac
    shift
done

if [[ ! -d $confdir ]]; then
    echo "$TDH_PNAME Error locating tdh_config direstory '$confdir'"
    exit 1
fi


mapComponents "$confdir"


# SYNC-TO
if [ $syncto -eq 1 ]; then

    for comp in ${components[@]}; do
        target="${comp}/"
        source="${confdir}/${comp##*\/}/"

        echo "rsync -aC $source $target"
        if [ $dryrun -eq 0 ]; then
            ( rsync -aC $source $target )
        fi
    done
else # SYNC-FROM
    for comp in ${components[@]}; do
        target="${confdir}/${comp##*\/}/conf/"
        source="${comp}/conf/"

        if [[ ! -d $target ]]; then
            if [ $quiet -eq 0 ]; then
                echo "Target directory '$target' does not exist!"
                #ask "Do you want to create it? (y/N) " N
                if [[ $? -eq 0 && $dryrun -eq 0 ]]; then
                    ( mkdir -p $target )
                fi
            else
                echo " -> Skipping non-existant target '$target'"
                continue
            fi
        fi

        echo "rsync -aX $source $target"
        if [ $dryrun -eq 0 ]; then
            ( rsync -aC $source $target )
        fi
    done
fi

echo "$TDH_PNAME finished."

exit $? 
