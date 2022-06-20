#!/usr/bin/env bash
#
# tdh-sync-config.sh
#
confdir=
syncto=1
dryrun=0
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

TDH_HOME="${TDH_HOME:-/opt/TDH}"

# -----------

usage="
Synchronized the cluster configuration from a configuration repo
to the current environment ie. TDH_HOME. Optionally can reverse 
direction and '--sync-from' the environment back to the config repo.

Synopsis:
  $TDH_PNAME [-hSqV] [config_path]

Options:
  -h|--help       : Show usage info and exit.
  -n|--dryrun     : Enable rsync dryrun
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
            components+=("${cpath##*\/}")
        fi
    done
}


# -----------
# Main
rt=0

while [ $# -gt 0 ]; do
    case "$1" in 
    'help'|-h|--help)
        echo "$TDH_PNAME [options] [config_path_envname]"
        echo "  default is sync-to \$TDH_HOME"
        echo "  -S or --sync-from will reverse and sync from" 
        echo "  the environment to the config repo"
        exit 0
        ;;
    -n|--dryrun|--dry-run)
        echo " -> DRYRUN enabled."
        dryrun=1
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

tdh_version
mapComponents 

args=("--archive" "--cvs-exclude" "--verbose")
if [ $dryrun -eq 1 ]; then
    args+=("--dry-run")
fi

# SYNC-TO
if [ $syncto -eq 1 ]; then
    printf "\n ${C_GRN}-> SYNC TO: ${C_NC}${C_MAG}${TDH_HOME} ${C_NC} \n"

    for comp in ${components[@]}; do
        printf "\n${C_YEL}${comp} ${C_NC} \n"

        conf="conf"
        if [[ "${comp%%-*}" == "hadoop" ]]; then
            conf="etc/hadoop"
        fi
        target="${TDH_HOME}/${comp}/${conf}/"
        source="${confdir}/${comp##*\/}/${conf}/"

        echo "( rsync ${args[@]} $source $target )"
        ( rsync ${args[@]} $source $target )

        rt=$?
        if [ $rt -ne 0 ]; then
            echo " -> Error in rsync"
            break
        fi
    done

else 
    printf "\n ${C_GRN}-> SYNC FROM: ${C_NC}${C_MAG}${TDH_HOME}${C_NC} \n"

    for comp in ${components[@]}; do
        printf "\n${C_YEL}${comp} ${C_NC} \n"

        conf="conf"
        if [[ "${comp%%-*}" == "hadoop" ]]; then
            conf="etc/hadoop"
        fi
        target="${confdir}/${comp##*\/}/${conf}/"
        source="${TDH_HOME}/${comp}/${conf}/"

        echo "( rsync ${args[@]} $source $target )"
        ( rsync ${args[@]} $source $target )

        rt=$?
        if [ $rt -ne 0 ]; then
            echo " -> Error in rsync"
            break
        fi
    done
fi

echo "$TDH_PNAME finished."

exit $rt
