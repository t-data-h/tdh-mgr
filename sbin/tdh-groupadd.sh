#!/usr/bin/env bash
#
#  Distributed group add for a given user.
#
PNAME=${0##*\/}

users=
groups=
hosts=

clush=$(which clush 2>/dev/null)
ansible=$(which ansible 2>/dev/null)
usermod="usermod -a -G"
default_hosts="tdh-m01 tdh-m02 tdh-m03 tdh-d01 tdh-d02 tdh-d03 tdh-d04"
use_clush=1
ssh=0

usage="
Tool for adding a list of groups to an existing user across a 
set of servers, as defined by \$TDH_HOSTS

Synopsis:
  $PNAME [options]  <user_a user_b ...> 
 
Options:
  -a|--ansible          : Prefer ansible by default to configure host groups.
  -G|--groups <groups>  : Comma-delimited list of groups, eg. 'users,wheel,video'
  -H|--hosts <hosts>    : Comma-delimited list of hosts, overrides \$TDH_HOSTS.
  -h|--help             : Show usage info and exit.
  -s|--ssh              : Prefer ssh over clush.

  By default, the order of preference is clush > ansible > ssh.
"

# -------------------
#
rt=0
 
if [ -n "$TDH_HOSTS" ]; then
    hosts="$TDH_HOSTS"
fi

while [ $# -gt 0 ]; do
    case "$1" in
        'help'|-h|--help)
            echo "$usage"
            exit 0
            ;;
        -a|--ansible)
            use_clush=0
            ;;
        -G|--groups)
            groups="$2"
            shift
            ;;
        -H|--hosts)
            hosts="$2"
            shift
            ;;
        -s|--ssh)
            ssh=1
            ;;
        *)
            users="$@"
            shift $#
            ;;
     esac
     shift
 done

if [ -z "$hosts" ]; then
    hosts="$default_hosts"
fi

if [ -z "$groups" ] || [ -z "$users" ]; then
    echo "$PNAME Error, Invalid or missing parameters" >&2
    echo "$usage"
    exit 1
fi

groups=$(echo "$groups" | sed "s/,/ /g")
users=$(echo "$users" | sed "s/,/ /g")

for group in $groups; do
    for user in $users; do
        cmd="$usermod $group $user"
        if [[ -n "$clush" && $ssh -eq 0 && $ans -eq 0 ]]; then
            ( $clush -a "$cmd" )
            rt=$?
        elif [[ -n "$ansible" && $ssh -eq 0 ]]; then
            ( $ansible -a "$cmd" )
            rt=$?
        else
            for host in $hosts; do
                echo "( ssh $host \"sudo $cmd\" )"
                ( ssh $host "sudo $cmd" )
                rt=$?
                if [ $rt -ne 0 ]; then
                    echo "Error in ssh command" >&2
                    break
                fi
            done
        fi
    done
done

echo "$PNAME Finished."
exit $rt

