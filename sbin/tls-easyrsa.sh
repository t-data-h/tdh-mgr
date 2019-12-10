#!/bin/bash
#
# Wrapper script for using EasyRSA3 to generate and optionally
# sign host certificates.
# This utilizes an existing EasyRSA installation, which should be
# provided by the -e or --easyrsa parameter.
#
PNAME=${0##*\/}

easyrsa=
reqorsign=
rt=1

usage()
{
    echo ""
    echo "Usage: $PNAME [options] [action] host1 host2 ..."
    echo "  -h|--help            : Display help info and exit"
    echo "  -e|--easyrsa <path>  : Path to EasyRSA (with existing pki)."
    echo "    <action>           : Action is either 'gen-req' or 'sign'."
    echo ""
    echo "  TDH_HOSTS can be set to provide list of hosts and "
    echo "  will override any provided hosts"
    echo ""
}

#
# MAIN

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
    echo " Please provide the path the easyrsa3 directory via -e|--easyrsa"
    echo " Specifically the path to the easyrsa binary and './pki' subdir."
    exit $rt
fi


echo ""
if [[ ${action,,} =~ ^gen.* ]]; then
    echo "$PNAME Generating Certificate requests.."
    reqorsign=0
elif [[ ${action,,} =~ ^sign$ ]; then
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
