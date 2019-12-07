#!/bin/bash
#
#
PNAME=${0##*\/}

easyrsa=
reqorsign=0
rt=1

usage()
{
    echo ""
    echo "Usage: $PNAME [options] [action] host1 host2 ..."
    echo "  -h|--help            : Display help info and exit"
    echo "  -e|--easyrsa <path>  : Path to easyrsa pki"
    echo "    <action>           : Action is either 'gen' or 'sign'"
    echo ""
    echo "  TDH_HOSTS can be set to provide list of hosts and "
    echo "  will override any provided hosts"
    echo ""
}


while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -e|--easyrsa)
            easyrsa="$2"
            shift
            ;;
        *)
            action="$1"
            shift
            hosts="$@"
            shift $#
            ;;
    esac
    shift
done


if [ -n "$TDH_HOSTS" ]; then
    hosts="$TDH_HOSTS"
fi

if [ -z "$hosts" ]; then
    echo "Error, No hosts provided!"
    usage
    exit $rt
fi

if [ -n "$easyrsa" ] && [ -d "$easyrsa" ]; then
    cd $easyrsa
fi

if ! [ -e "./easyrsa" ]; then
    echo "Error locating EasyRSA!"
    echo " Please provide the path the easyrsa3 pki directory via -e|--easyrsa"
    exit $rt
fi


echo ""
if [ $action == "req" ]; then
    echo "$PNAME Generating Certificate requests.."
elif [ $action == "sign" ]; then
    echo "$PNAME Signing certificate requests.."
    reqorsign=1
else
    echo "Invalid action. Valid option should be 'req' or 'sign'"
    exit $rt
fi


for hostname in $hosts; do
    shortname=${hostname%%\.*}

    if [ -z "$shortname" ]; then
        echo "Error! Provided hostname '$hostname' is not a fully qualified domain name"
        exit $rt
    fi

    if [ $reqorsign -eq 0 ]; then   # gen-req
        ( cd $easyrsa; ./easyrsa gen-req $hostname nopass )
    else   # sign req
        ( cd $easyrsa; \
         ./easyrsa --subject-alt-name="DNS:${hostname},DNS:${shortname}" sign-req serverclient $hostname )
    fi

    rt=$?
done

echo "$PNAME Finished."
exit $rt
