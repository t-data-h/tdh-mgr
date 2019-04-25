#!/bin/bash
#
#  Sets up oud internal IP or pseudo-ip on a given interface. By default
#  vmnet8 from vmware is used.
#
PNAME=${0##*\/}
AUTHOR="Timothy C. Arland <tcarland@gmail.com>"
VERSION="v0.1.6"



usage()
{
    echo ""
    echo "Usage: $PNAME [-i interface]  start|stop|status"
    echo "  -h|--help      : Display usage info and exit."
    echo "  -i|--interface : Name of a system interface; default is 'vmnet8'"
    echo "  -I|--ip        : Alternate bind address to use, the default is:"
    echo "                     $(hostname -i)/24"
    echo "  -V|--version   : Display version and exit"
    echo ""
    echo "      Note the /24 netmask is assumed above but should"
    echo "      always be provided when setting an alternate ip address"
    echo ""
}


version()
{
    echo ""
    echo "$PNAME Version: $VERSION by $AUTHOR"
    echo ""
}


hostip_is_valid()
{
    local hostid=`hostname`
    local hostip=`hostname -i`
    local fqdn=`hostname -f`
    local iface=
    local ip=
    local rt=1

    if [ "$hostip" == "127.0.0.1" ]; then
        echo "   <lo> "
        echo "  WARNING! Hostname is set to localhost, aborting.."
        return $rt
    fi

    IFS=$'\n'

    for line in $(ip addr list | grep "inet ")
    do
        IFS=$' '
        iface=$(echo $line | awk -F' ' '{ print $NF }')
        ip=$(echo $line | awk '{ print $2}' | awk -F'/' '{ print $1 }')

        if [ "$ip" == "$hostip" ]; then
            rt=0
            break
        fi
    done

    echo ""
    echo "$fqdn"
    echo -n "[$hostid]"

    if [ $rt -eq 0 ]; then
        echo " : $hostip : <$iface>"
    else
	echo " : <No Interface bound>"
    fi

    return $rt
}


#-------------------------------------------------------------
# Main
ACTION=
BINDIP="$(hostname -i)/24"

# parse options
while [ $# -gt 0 ]; do
    case "$1" in
        -b|--bandwidth)
            BW="$2"
            shift
            ;;
        -D|--no-delete)
            DELETE=0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -i|--interface)
            IFACE="$2"
            shift
            ;;
        -I|--ip)
            BINDIP="$2"
            shift;
            ;;
        -V|--version)
            version
            exit 0
            ;;
        *)
            ACTION="$1"
            shift
            ;;
    esac
done


if [ -z "$IFACE" ]; then
    IFACE="vmnet8"
fi

rt=0

if [ "$ACTION" == "start" ]; then

    hostip_is_valid
    rt=$?

    if [ $rt -ne 0 ]; then
        echo ""
	    echo "  Binding $BINDIP to interface $IFACE"

        ( ip addr add $BINDIP dev $IFACE )
        rt=$?

        hostip_is_valid
    fi

elif [ "$ACTION" == "stop" ]; then

    ( ip addr del $BINDIP dev $IFACE )
    rt=$?

    hostip_is_valid

elif [ "$ACTION" == "status" ]; then

    hostip_is_valid
    rt=$?
    echo ""

else
    usage
fi

echo ""
exit $rt
