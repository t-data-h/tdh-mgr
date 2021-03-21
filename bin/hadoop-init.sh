#!/usr/bin/env bash
#
#  Init script for the core hadoop services HDFS and YARN.
#
#  Timothy C. Arland <tcarland@gmail.com>
#

# ----------- preamble
HADOOP_ENV="tdh-env.sh"
HADOOP_ENV_PATH="/opt/TDH/etc"

if [ -r "./etc/$HADOOP_ENV" ]; then
    . ./etc/$HADOOP_ENV
    HADOOP_ENV_PATH="./etc"
elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
    . /etc/hadoop/$HADOOP_ENV
    HADOOP_ENV_PATH="/etc/hadoop"
elif [ -r "${HADOOP_ENV_PATH}/${HADOOP_ENV}" ]; then
    . $HADOOP_ENV_PATH/$HADOOP_ENV
fi

if [ -z "$TDH_VERSION" ]; then
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi
if [ -z "$HADOOP_CONF_DIR" ]; then
    echo "Fatal! HADOOP_CONF_DIR not set."
    exit 2
fi
# -----------

HOST=$( hostname -s )
HADOOP_VER=$(readlink $HADOOP_HOME)
HDFS_CONF="${HADOOP_CONF_DIR}/hdfs-site.xml"
YARN_CONF="${HADOOP_CONF_DIR}/yarn-site.xml"
NODE_CONF="${HADOOP_CONF_DIR}/workers"

NN_ID="namenode.NameNode"
SN_ID="namenode.SecondaryNameNode"
JN_ID="qjournal.server.JournalNode"
FC_ID=""
RM_ID="resourcemanager.ResourceManager"
DN_ID="datanode.DataNode"
NM_ID="nodemanager.NodeManager"

NS_NAME=$( grep -A1 'dfs.nameservices' $HDFS_CONF | \
  grep value 2>/dev/null | sed -E 's/.*<value>(.*)<\/value>/\1/' 2>/dev/null )

JN_EDITS=$( grep -A1 'dfs.namenode.shared.edits.dir' $HDFS_CONF | \
  grep value 2>/dev/null | sed -E 's/.*<value>(.*)<\/value>/\1/' 2>/dev/null )

RM1=$( grep -A1 'yarn.resourcemanager.address' ${YARN_CONF} | \
  grep value 2>/dev/null | sed -E 's/.*<value>(.*)<\/value>/\1/' |  awk -F':' '{ print $1 }' )

NNS=    # namenodes list
JNS=    # journalnodes
NN1=
NN2=
IS_HA=

# -----------
# NSCACHE
nscache="${HADOOP_HOME}/.ns_cache"
cache_timeout_sec=800

# cache expired? note 'stat -c' is not portable
if [[ -f $nscache && $(( $(date +%s) - $(stat -c %Y $nscache) )) > $cache_timeout_sec ]]; then
    ( rm $nscache )
fi
# cache nameservers to avoid very slow 'getconf'
if [ -f ${nscache} ]; then 
    NNS=$(cat ${nscache} | head -1)
    if [ -z "$NS_NAME" ]; then 
        NN2=$(cat ${nscache} | tail -1)
    fi
else
    NNS=$($HADOOP_HOME/bin/hdfs getconf -namenodes 2>/dev/null)
    ( echo $NNS > ${nscache} )
    if [ -z "$NS_NAME" ]; then
        NN2=$($HADOOP_HOME/bin/hdfs getconf -secondaryNamenodes)
        ( echo $NN2 >> ${nscache} )
    fi
fi

# -----------
# HA Config
JNS=$(echo "$JN_EDITS" | sed 's,qjournal://\([^/]*\)/.*,\1,g; s/;/ /g; s/:[0-9]*//g')
NN1=$(echo $NNS | awk '{ print $1 }')

if [ -n "$NS_NAME" ]; then
    NN2=$(echo $NNS | awk '{ print $2 }')
    SN_ID="$NN_ID"
    IS_HA=0
else
    IS_HA=1
fi

# -----------
# Datanodes
if [ ! -e $NODE_CONF ]; then
    NODE_CONF="${HADOOP_CONF_DIR}/slaves"
fi
NODES=$(cat $NODE_CONF)

# ---------------------------------------------------

usage="
$TDH_PNAME {start|stop|status} <start-journals-only>
  TDH $TDH_VERSION
"

# ---------------------------------------------------

show_status()
{
    local rt=0
    local r=0

    hostip_is_valid
    rt=$?
    if [ $rt -ne 0 ]; then
        echo "$PNAME Error, unable to locate the host network interface. "
        echo "  Please verify networking is configured properly."
        echo ""
        return 3
    fi

    tdh_show_header $HADOOP_VER

    # HDFS Primary Namenode
    check_remote_process $NN1 $NN_ID

    rt=$?
    if [ $rt -eq 0 ]; then
        printf " HDFS Namenode (pri)    | $C_GRN OK $C_NC | [${NN1}:${PID}]\n"
    else
        printf " HDFS Namenode (pri)    | ${C_RED}DEAD$C_NC | [$NN1]\n"
        r=1
    fi

    # HDFS Secondary Namenode
    check_remote_process $NN2 $SN_ID

    rt=$?
    if [ $rt -eq 0 ]; then
        printf " HDFS NameNode (sec)    | $C_GRN OK $C_NC | [${NN2}:${PID}]\n"
    else
        printf " HDFS Namenode (sec)    | ${C_RED}DEAD$C_NC | [${NN2}]\n"
        r=1
    fi

    # YARN ResourceManager
    check_remote_process $RM1 $RM_ID

    rt=$?
    if [ $rt -eq 0 ]; then
        printf " YARN ResourceManager   | $C_GRN OK $C_NC | [${RM1}:${PID}]\n"
    else
        printf " YARN ResourceManager   | ${C_RED}DEAD$C_NC | [${RM1}]\n"
        r=1
    fi

    if [ $IS_HA -eq 0 ] && [ -n "$JNS" ]; then
        tdh_show_separator

        for jn in $JNS; do
            check_remote_process $jn $JN_ID

            rt=$?
            if [ $rt -eq 0 ]; then
                printf " HDFS JournalNode       | $C_GRN OK $C_NC | [${jn}:${PID}]\n"
            else
                printf " HDFS JournalNode       | ${C_RED}DEAD$C_NC | [${jn}]\n"
                r=1
            fi
        done
    fi


    IFS=$'\n'

    for dn in $NODES; do
        tdh_show_separator

        # HDFS DataNode
        check_remote_process $dn $DN_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            printf " HDFS DataNode          | $C_GRN OK $C_NC | [${dn}:${PID}]\n"
        else
            printf " HDFS DataNode          | ${C_RED}DEAD$C_NC | [${dn}]\n"
            r=1
        fi

        # YARN NodeManager
        check_remote_process $dn $NM_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            printf " YARN NodeManager       | $C_GRN OK $C_NC | [${dn}:${PID}]\n"
        else
            printf " YARN NodeManager       | ${C_RED}DEAD$C_NC | [$dn]\n"
            r=1
        fi
    done

    if [ $r -gt 0 ]; then
        ( rm $nscache )
    fi

    return $r
}


# =================
#  MAIN
# =================
ACTION=
OPT=
rt=0

while [ $# -gt 0 ]; do
    case "$1" in
        -Q|-q|--quiet)
            quiet=1
            ;;
        *)
            ACTION="$1"
            OPT="$2"
            shift $#
            ;;
    esac
    shift
done


case "$ACTION" in
    'start')
        hostip_is_valid

        rt=$?
        if [ $rt -ne 0 ]; then
            printf "$TDH_PNAME Error, Unable to find a network interface. Please verify networking is configured properly. \n"
            exit $rt
        fi

        tdh_show_header $HADOOP_VER

        # only start journalnodes first on request, this is needed for formatting HDFS
        if [[ "${OPT,,}" =~ "journal" ]]; then
            case "$JN_EDITS" in
                qjournal://*)
                    if [ -z "$JNS" ]; then
                        printf "$TDH_PNAME Error determining Journal Nodes \n"
                        exit 1
                    fi
                    printf "Starting HDFS Journal Nodes.. [${JNS}] \n"
                    ( $HADOOP_HOME/bin/hdfs \
                      --config "$HADOOP_CONF_DIR" \
                      --hostnames "$JNS" \
                      --daemon start journalnode >/dev/null 2>&1 )
                    ;;
            esac
            exit 0
        fi

        printf "Starting HDFS.. [${NN1}] \n"
        ( sudo -u $HADOOP_USER $HADOOP_HDFS_HOME/sbin/start-dfs.sh > /dev/null 2>&1 )

        printf "Starting YARN.. [${RM1}] \n"
        ( ssh $RM1 "sudo -u $HADOOP_USER $HADOOP_YARN_HOME/sbin/start-yarn.sh" > /dev/null 2>&1 )
        ;;

    'stop')
        tdh_show_header $HADOOP_VER

        printf "Stopping YARN.. [${RM1}] \n"
        ( ssh $RM1 "sudo -u $HADOOP_USER $HADOOP_YARN_HOME/sbin/stop-yarn.sh" > /dev/null 2>&1 )

        printf "Stopping HDFS.. [${NN1}] \n"
        ( sudo -u $HADOOP_USER $HADOOP_HDFS_HOME/sbin/stop-dfs.sh > /dev/null 2>&1 )
        rt=0
        ;;

    'status'|'info')
        show_status
        rt=$?
        ;;

    'help'|--help|-h)
        echo "$usage" 
        ;;

    'version'|--version|-V)
        tdh_show_header $HADOOP_VER
        tdh_version
        ;;

    *)
        echo "$usage"
        ;;
esac

exit $rt
