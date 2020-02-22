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

NN_ID="namenode.NameNode"
SN_ID="namenode.SecondaryNameNode"
JN_ID="qjournal.server.JournalNode"
RM_ID="resourcemanager.ResourceManager"
DN_ID="datanode.DataNode"
NM_ID="nodemanager.NodeManager"

HOST=$( hostname -s )
MASTERS="${HADOOP_HOME}/etc/hadoop/masters"
HDFS_CONF="${HADOOP_HOME}/etc/hadoop/hdfs-site.xml"
YARN_CONF="${HADOOP_HOME}/etc/hadoop/yarn-site.xml"

NS_NAME=$( grep -A1 'dfs.nameservices' ${HDFS_CONF} | \
  grep value | \
  sed -E 's/.*<value>(.*)<\/valude>/\1/' 2>/dev/null )

if [ -n "$NS_NAME" ]; then
    NN_HOST=$( grep -A1 'dfs.namenode.http-address' ${HDFS_CONF} | \
      grep -A1 'nn1' | grep value | \
      sed -E 's/.*<value>(.*)<\/value>/\1/' | \
      awk -F':' '{ print $1 }' )
    SN_HOST=$( grep -A1 'dfs.namenode.http-address' ${HDFS_CONF} | \
      grep -A1 'nn2' | grep value | \
      sed -E 's/.*<value>(.*)<\/value>/\1/' | \
      awk -F':' '{ print $1 }' )
    IS_HA=0
    SN_ID="$NN_ID"
else
    NN_HOST=$( grep -A1 'dfs.namenode.http-address' ${HDFS_CONF} | \
      grep value | \
      sed -E 's/.*<value>(.*)<\/value>/\1/' | \
      awk -F':' '{ print $1 }' )
    SN_HOST=$( grep -A1 'dfs.namenode.secondary' ${HDFS_CONF} | \
      grep value | \
      sed -E 's/.*<value>(.*)<\/value>/\1/' | \
      awk -F':' '{ print $1 }' )
    IS_HA=1
fi

RM_HOST=$( grep -A1 'yarn.resourcemanager.address' ${YARN_CONF} | \
  grep value | \
  sed -E 's/.*<value>(.*)<\/value>/\1/' | \
  awk -F':' '{ print $1 }' )


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

    echo -e " -------- ${C_CYN}${HADOOP_VER}${C_NC} --------- "

    # HDFS Primary Namenode
    #
    check_remote_process $NN_HOST $NN_ID

    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e " HDFS Namenode (pri)    | $C_GRN OK $C_NC | [${NN_HOST}:${PID}]"
    else
        echo -e " HDFS Namenode (pri)    | ${C_RED}DEAD$C_NC | [$NN_HOST]"
        r=1
    fi

    # HDFS Secondary Namenode
    #
    check_remote_process $SN_HOST $SN_ID

    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e " HDFS NameNode (sec)    | $C_GRN OK $C_NC | [${SN_HOST}:${PID}]"
    else
        echo -e " HDFS Namenode (sec)    | ${C_RED}DEAD$C_NC | [${SN_HOST}]"
        r=1
    fi

    # YARN ResourceManager
    #
    check_remote_process $RM_HOST $RM_ID

    rt=$?
    if [ $rt -eq 0 ]; then
        echo -e " YARN ResourceManager   | $C_GRN OK $C_NC | [${RM_HOST}:${PID}]"
    else
        echo -e " YARN ResourceManager   | ${C_RED}DEAD$C_NC | [${RM_HOST}]"
        r=1
    fi

    set -f
    IFS=$'\n'

    if [ $IS_HA -eq 0 ] && [ -r $MASTERS ]; then
        echo -e "      -------------     |------|"
        for jn in $( cat $MASTERS ); do
            check_remote_process $jn $JN_ID

            rt=$?
            if [ $rt -eq 0 ]; then
                echo -e " HDFS JournalNode       | $C_GRN OK $C_NC | [${jn}:${PID}]"
            else
                echo -e " HDFS JournalNode       | ${C_RED}DEAD$C_NC | [${jn}]"
                r=1
            fi
        done
    fi

    nodes="${HADOOP_HOME}/etc/hadoop/workers"
    if ! [ -e $nodes ]; then
        nodes="${HADOOP_HOME}/etc/hadoop/slaves"
    fi

    r=0
    for dn in $( cat ${nodes} ); do
        echo -e "      -------------     |------|"

        check_remote_process $dn $DN_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo -e " HDFS DataNode          | $C_GRN OK $C_NC | [${dn}:${PID}]"
        else
            echo -e " HDFS DataNode          | ${C_RED}DEAD$C_NC | [${dn}]"
            r=1
        fi

        check_remote_process $dn $NM_ID

        rt=$?
        if [ $rt -eq 0 ]; then
            echo -e " YARN NodeManager       | $C_GRN OK $C_NC | [${dn}:${PID}]"
        else
            echo -e " YARN NodeManager       | ${C_RED}DEAD$C_NC | [$dn]"
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

        check_remote_process $RM_HOST $RM_ID
        rt=$?
        if [ $rt -eq 0 ]; then
            echo " YARN Resource Manager is already running  [$PID]"
            #exit $rt
        fi

        check_remote_process $NN_HOST $NN_ID
        rt=$?
        if [ $rt -eq 0 ]; then
            echo " HDFS Namenode is already running  [$PID]"
            #exit $rt
        fi

        hostip_is_valid
        rt=$?
        if [ $rt -ne 0 ]; then
            echo " Error! Unable to find a network interface. Please verify networking is configured properly."
            exit $rt
        fi

        echo -e " -------- ${C_CYN}${HADOOP_VER}${C_NC} --------- "

        # only start journalnodes first on request
        if [[ "${OPT,,}" =~ "journal" ]]; then
            jn_edits=$($HADOOP_HDFS_HOME/bin/hdfs getconf -confKey dfs.namenode.shared.edits.dir 2>&-)
            case "$jn_edits" in
                qjournal://*)
                    jn_hosts=$(echo "$jn_edits" | sed 's,qjournal://\([^/]*\)/.*,\1,g; s/;/ /g; s/:[0-9]*//g')
                    if [ -z "$jn_hosts" ]; then
                        echo "Error determining Journal Nodes"
                        exit 1
                    fi
                    echo "Starting HDFS Journal Nodes.."
                    ( $HADOOP_HDFS_HOME/sbin/hadoop-daemons.sh \
                      --config "$HADOOP_CONF_DIR" \
                      --hostnames "$jn_hosts" \
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
