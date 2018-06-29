#!/bin/bash
#
PNAME=${0##*\/}
VERSION="0.022"
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"

HADOOP_ENV="hadoop-env-user.sh"

HADOOP_LOGDIR=
dryrun=0

# source the hadoop-env-user script
if [ -z "$HADOOP_ENV_USER" ]; then
    if [ -r "$HOME/hadoop/etc/$HADOOP_ENV" ]; then
        HADOOP_ENV="$HOME/hadoop/etc/$HADOOP_ENV"
    elif [ -r "/etc/hadoop/$HADOOP_ENV" ]; then
        HADOOP_ENV="/etc/hadoop/$HADOOP_ENV"
    elif [ -r "./$HADOOP_ENV" ]; then
        HADOOP_ENV="./$HADOOP_ENV"
    fi
    source $HADOOP_ENV
fi

if [ -z "$HADOOP_LOGDIR" ] ; then
    HADOOP_LOGDIR="/var/log/hadoop"
fi


usage()
{
    echo "Usage: $PNAME [options]"
    echo "  --dryrun | -n  =  Dryrun, files to be removed are listed only"
    echo "  --help   | -h  =  Display usage info and exit"
    echo ""
    return 1
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
    
    echo "erase_all $cwd"

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
        -n|--dryrun)
            dryrun=1
            echo "  <DRYRUN Enabled>"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            ;;
    esac
    shift
done


echo "HADOOP_LOGDIR=\"$HADOOP_LOGDIR\"" 
erase_all "$HADOOP_LOGDIR"
rt=$?

exit $rt

