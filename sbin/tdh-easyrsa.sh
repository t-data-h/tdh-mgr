#!/bin/bash
#
# Wrapper script for using EasyRSA3 to generate and sign host certificates.
# This utilizes an existing EasyRSA installation, which should be
# provided by the -e or --easyrsa parameter.
# This also expects an x509type of 'serverclient' which may not be defined
# in the original EasyRSA3 repository.
# Simply copy the 'server' profile and add 'clientAuth' to the extended options.
#  extendedKeyUsage = serverAuth,clientAuth
#
PNAME=${0##*\/}
VERSION="V0.5.2"

easyrsa="./easyrsa3"
reqorsign=
x509type="serverclient"  # options are 'server', 'client', or 'serverclient'

# ------------------------

usage()
{
    echo ""
    echo "Usage: $PNAME [options] [action] host1 host2 [..]"
    echo "  -h|--help            : Display help info and exit."
    echo "  -e|--easyrsa <path>  : Path to EasyRSA3 (with existing pki config)."
    echo "  -x|--x509type <type> : Name of x509 type (default is 'serverclient')."
    echo "  -V|--version         : Show version info and exit."
    echo "    <action>           : Action is either 'gen-req' or 'sign-req'."
    echo ""
    echo "  TDH_HOSTS can be set to provide list of hosts and "
    echo "  will override any command provided hosts"
    echo ""
}

# ------------------------
# MAIN
#
rt=1

while [ $# -gt 0 ]; do
    case "$1" in
        'help'|-h|--help)
            usage
            exit 0
            ;;
        -e|--easyrsa)
            easyrsa="$2"
            shift
            ;;
        -x|--x509type)
            x509type="$2"
            shift
            ;;
        'version'|-V|--version)
            echo "$PNAME $VERSION"
            exit 0
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

if ! [ -x "./easyrsa" ]; then
    echo "Error locating EasyRSA.."
    echo " Please provide the path the easyrsa3 directory via -e|--easyrsa"
    echo " Specifically the path to the easyrsa binary and './pki' subdir."
    exit $rt
fi

echo ""
if [[ ${action,,} =~ ^gen.* ]]; then
    echo "$PNAME Generating Certificate requests.."
    reqorsign=0
elif [[ ${action,,} =~ ^sign$ ]]; then
    echo "$PNAME Signing certificate requests.."
    reqorsign=1
else
    echo "Invalid action. Valid option should be 'req' or 'sign'"
    exit $rt
fi


for hostname in $hosts; do
    shortname=${hostname%%\.*}

    if [ -z "$shortname" ]; then
        echo "Error, provided hostname '$hostname' is not a fully qualified domain name."
        echo "Skipping host '$hostname'"
        continue
    fi

    if [ $reqorsign -eq 0 ]; then   # gen-req
        ( cd $easyrsa; ./easyrsa gen-req $hostname nopass )
    else   # sign req
        ( cd $easyrsa; \
         ./easyrsa \
           --subject-alt-name="DNS:${hostname},DNS:${shortname}" \
           sign-req serverclient $hostname )
    fi

    rt=$?
done

echo "$PNAME Finished."
exit $rt
