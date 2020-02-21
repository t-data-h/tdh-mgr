#!/bin/bash
#
#  tdh-mysql-init.sh
#   Creates MySQL Server Docker Container
#
#  Timothy C. Arland <tcarland@gmail.com>

tdh_path=$(dirname "$(readlink -f "$0")")

# ----------- preamble
HADOOP_ENV="tdh-env-user.sh"
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
    echo "Fatal! Unable to locate TDH Environment '$HADOOP_ENV'"
    exit 1
fi
# -----------

docker_image="mysql/mysql-server:5.7"

name="tdh-mysql1"
mycnf="$(realpath ${HADOOP_ENV_PATH})/mysqld-tdh.cnf"
port="3306"
network=
volname=
res=
ACTION=


usage()
{
    echo ""
    echo "Usage: $TDH_PNAME [options] run|pull|pw"
    echo "   -h|--help             = Display usage and exit."
    echo "   -n|--name <name>      = Name of the Docker Container instance."
    echo "   -N|--network <name>   = Attach container to Docker network"
    echo "                           Default uses 'host' networking."
    echo "   -p|--port <port>      = Local bind port for the container."
    echo "   -V|--version          = Show version info and exit"
    echo ""
    echo " Creates and initializes a mysqld docker container."
    echo ""
    echo " Any other action than 'run' results in a dry run."
    echo " The container will only start with the run or start action."
    echo " The 'pull' command fetches the docker image:version."
    echo " The 'pw' command will attempt to detect the temporary password"
    echo " created at startup from the container logs."
    echo ""
}


validate_network()
{
    local net="$1"
    local res=

    res=$( docker network ls | awk '{print $2 }' | grep "$net" )

    if [ -z "$res" ]; then
        echo "Creating bridge network: $net"
        ( docker network create --driver bridge $net )
    else
        echo "Attaching container to bridge network '$net'"
    fi

    return 0
}


while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -N|--network)
            network="$2"
            shift
            ;;
        -n|--name)
            name="$2"
            shift
            ;;
        -p|--port)
            port="$2"
            shift
            ;;
        -V|--version)
            version
            exit 0
            ;;
        *)
            ACTION="${1,,}"
            shift
            ;;
    esac
    shift
done

if [ -z "$ACTION" ]; then
    usage
fi

if [[ $ACTION == "pw" ]]; then
    passwd=$( docker logs tdh-mysql1 2>&1 | grep GENERATED | awk -F': ' '{ print $2 }' )
    echo "Mysqld root password: '$passwd'"
    exit 0
fi

volname="${name}-data1"

cmd="docker run --name $name -d"

if [ -n "$network" ]; then
    validate_network "$network"
    cmd="$cmd -p $port:3306"
else
    network="host"
fi

cmd="$cmd --network $network"
cmd="$cmd --mount type=bind,src=${mycnf},dst=/etc/my.cnf \
--mount type=volume,source=${volname},target=/var/lib/mysql \
--env MYSQL_RANDOM_ROOT_PASSWORD=true \
--env MYSQL_LOG_CONSOLE=true \
${docker_image} \
--character-set-server=utf8 --collation-server=utf8_general_ci"

#  initialization scripts
# --mount type=bind,src=/path-on-host-machine/scripts/,dst=/docker-entrypoint-initdb.d/ \

echo ""
echo "  TDH Docker Container: '${name}'"
echo "  Docker Image: ${docker_image}"
echo "  Container Volume: '${volname}'"
echo "  Docker Network: ${network}"
echo "  Local port: ${port}"
echo ""

if [[ $ACTION == "run" || $ACTION == "start" ]]; then

    if [ ! -f $mycnf ]; then
        echo "Error locating mysql config: '$mycnf'"
        exit 1
    fi

    echo "Starting container '$name'"

    ( $cmd )
    ( sleep 6 )  # allow mysqld to start and generate password

    if [ $? -ne 0 ]; then
        echo "Error in docker run"
        exit 1
    fi

    echo -n "Checking for password. "
    for x in {1..3}; do
        passwd=$( docker logs tdh-mysql1 2>&1 | grep GENERATED | awk -F': ' '{ print $2 }' )
        if [ -n "$passwd" ]; then
            rt=0
            break
        fi
        echo -n ". "
        sleep 3
    done
    echo ""
    echo "passwd='$passwd'"
elif [[ $ACTION == "pull" ]]; then
    ( docker pull ${docker_image} )
else
    echo "  <DRYRUN> - Command to exec would be: "
    echo ""
    echo "( $cmd )"
    echo ""
fi

res=$?

if [ $res -ne 0 ]; then
    echo "ERROR in run for $PNAME"
    exit $res
fi

exit $res
