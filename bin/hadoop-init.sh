#!/bin/bash
#
#  Init script for the core hadoop services HDFS and YARN.
#
#  Timothy C. Arland <tcarland@gmail.com>
#

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"
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
# -----------

HADOOP_VER=$(readlink $HADOOP_HOME)
HDFS_CONF="${HADOOP_CONF_DIR}/hdfs-site.xml"
YARN_CONF="${HADOOP_CONF_DIR}/yarn-site.xml"

NN_ID="namenode.NameNode"
SN_ID="namenode.SecondaryNameNode"
JN_ID="qjournal.server.JournalNode"
FC_ID=""
RM_ID="resourcemanager.ResourceManager"
DN_ID="datanode.DataNode"
NM_ID="nodemanager.NodeManager"

HOST=$( hostname -s )

NS_NAME=$( grep -A1 'dfs.nameservices' $HDFS_CONF | \
  grep value | sed -E 's/.*<value>(.*)<\/valude>/\1/' 2>/dev/null )

JN_EDITS=$( grep -A1 'dfs.namenode.shared.edits.dir' $HDFS_CONF | \
  grep value | sed -E 's/.*<value>(.*)<\/valude>/\1/' 2>/dev/null )

RM1=$( grep -A1 'yarn.resourcemanager.address' ${YARN_CONF} | \
  grep value | sed -E 's/.*<value>(.*)<\/value>/\1/' |  awk -F':' '{ print $1 }' )

NNS=$($HADOOP_HOME/bin/hdfs getconf -namenodes 2>/dev/null)
JNS=$(echo "$JN_EDITS" | sed 's,qjournal://\([^/]*\)/.*,\1,g; s/;/ /g; s/:[0-9]*//g')
NN1=$(echo $NNS | awk '{ print $1 }')
NN2=$(echo $NNS | awk '{ print $2 }')

IS_HA=

if [ -n "$NS_NAME" ]; then
    SN_ID="$NN_ID"
    IS_HA=0
else
    NN2=$($HADOOP_HOME/bin/hdfs getconf -secondaryNamenodes)
    IS_HA=1
fi


# -----------


usage()
{
    echo "$TDH_PNAME {start|stop|status} <journal>"
    echo "  TDH Version: $TDH_VERSION"
}


show_status()
{
    local rt=0
    local r=0

    hostip_is_valid
    rt=$?
    if [ $rt -ne 0 ]; then
        echo "    Unable to locate the host network interface. "
        echo "    Please verify networking is configured properly."
        echo ""
        return 3
    fi

    printf " -------- ${C_CYN}${HADOOP_VER}${C_NC} --------- \n"

    # HDFS Primary Namenode
    #
    check_remote_process $NN1 $NN_ID

    rt=$?
    if [ $rt -eq 0 ]; then
        printf " HDFS Namenode (pri)    | $C_GRN OK $C_NC | [${NN1}:${PID}]\n"
    else
        printf " HDFS Namenode (pri)    | ${C_RED}DEAD$C_NC | [$NN1]\n"
        r=1
    fi

    # HDFS Secondary Namenode
    #
    check_remote_process $NN2 $SN_ID

    rt=$?
    if [ $rt -eq 0 ]; then
        printf " HDFS NameNode (sec)    | $C_GRN OK $C_NC | [${NN2}:${PID}]\n"
    else
        printf " HDFS Namenode (sec)    | ${C_RED}DEAD$C_NC | [${NN2}]\n"
        r=1
    fi

    # YARN ResourceManager
    #
    check_remote_process $RM1 $RM_ID

    rt=$?
    if [ $rt -eq 0 ]; then
        printf " YARN ResourceManager   | $C_GRN OK $C_NC | [${RM1}:${PID}]\n"
    else
        printf " YARN ResourceManager   | ${C_RED}DEAD$C_NC | [${RM1}]\n"
        r=1
    fi

    if [ $IS_HA -eq 0 ] && [ -n "$JNS" ]; then
        printf "      -------------     |------|\n"
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

    nodes="${HADOOP_HOME}/etc/hadoop/workers"
    if ! [ -e $nodes ]; then
        nodes="${HADOOP_HOME}/etc/hadoop/slaves"
    fi

    IFS=$'\n'
    r=0

    for dn in $( cat ${nodes} ); do
        printf "      -------------     |------|\n"

        check_remote_process $dn $DN_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            printf " HDFS DataNode          | $C_GRN OK $C_NC | [${dn}:${PID}]\n"
        else
            printf " HDFS DataNode          | ${C_RED}DEAD$C_NC | [${dn}]\n"
            r=1
        fi

        check_remote_process $dn $NM_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            printf " YARN NodeManager       | $C_GRN OK $C_NC | [${dn}:${PID}]\n"
        else
            printf " YARN NodeManager       | ${C_RED}DEAD$C_NC | [$dn]\n"
            r=1
        fi
    done

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
        -q|--quiet)
            quiet=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -V|--version)
            version
            exit 0
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
            echo " Error! Unable to find a network interface. Please verify networking is configured properly."
            exit $rt
        fi

        printf " -------- ${C_CYN}${HADOOP_VER}${C_NC} --------- \n"

        # only start journalnodes first on request
        if [[ "${OPT,,}" =~ "journal" ]]; then
            case "$JN_EDITS" in
                qjournal://*)
                    if [ -z "$JNS" ]; then
                        echo "Error determining Journal Nodes"
                        exit 1
                    fi
                    echo "Starting HDFS Journal Nodes.."
                    ( $HADOOP_HOME/sbin/hadoop-daemons.sh \
                      --config "$HADOOP_CONF_DIR" \
                      --hostnames "$JNS" \
                      --script "$HADOOP_HDFS_HOME/bin/hdfs" start journalnode >/dev/null 2>&1 )
                    ;;
            esac
            exit 0
        fi

        echo "Starting HDFS.."
        ( sudo -u $HADOOP_USER $HADOOP_HDFS_HOME/sbin/start-dfs.sh > /dev/null 2>&1 )

        echo "Starting YARN.."
        ( sudo -u $HADOOP_USER $HADOOP_YARN_HOME/sbin/start-yarn.sh > /dev/null 2>&1 )
        ;;

    'stop')
        echo -e " -------- ${C_CYN}${HADOOP_VER}${C_NC} --------- "

        echo "Stopping YARN.. [${RM_HOST}]"
        ( sudo -u $HADOOP_USER $HADOOP_YARN_HOME/sbin/stop-yarn.sh > /dev/null 2>&1 )

        echo "Stopping HDFS.. [${NN_HOST}]"
        ( sudo -u $HADOOP_USER $HADOOP_HDFS_HOME/sbin/stop-dfs.sh > /dev/null 2>&1 )
        rt=0
        ;;

    'status'|'info')
        show_status
        rt=$?
        ;;

    --version|-V)
        echo -e " -------- ${C_CYN}${HADOOP_VER}${C_NC} --------- "
        version
        ;;
    *)
        usage
        ;;
esac


exit $rt
