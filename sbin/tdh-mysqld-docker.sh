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

name="${TDH_DOCKER_MYSQL:-tdh-mysql01}"
mycnf="$(realpath ${HADOOP_ENV_PATH})/mysqld-tdh.cnf"
port="3306"
network=
volname=
ACTION=

# -----------

usage="
A script for creating and initializing a docker mysqld instance.

Synopsis:
  $TDH_PNAME [options] run|pull|pw

Options:
  -h|--help            :  Display usage and exit.
  -n|--name <name>     :  Name of the Docker Container instance.
                          Default container name is '${name}'.
  -N|--network <name>  :  Attach container to a Docker network.
                          Default uses 'host' networking.
  -p|--port <port>     :  Local bind port for the container.
  -V|--version         :  Show version info and exit
  
 Any other action than 'run' results in a dry run.
 The container will only start with the run or start action.
 The 'pull' command fetches the docker image:version.
 The 'pw' command will attempt to detect the temporary password
  created at startup from the container logs.
"

success="
 -> $TDH_PNAME successfully initialized mysqld container..

Initial connection to the instance via docker may require the Socket name:
  ( docker exec -it $name mysql -uroot -p -S /var/run/mysqld/mysqld.sock )
Set a new root password including from the host node.
  ALTER USER 'root'@'localhost' IDENTIFIED BY 'pw';
  GRANT ALL PRIVILEGES ON *.* TO 'root'@'hostname' IDENTIFIED BY 'pw' WITH GRANT OPTION;
"

# -----------

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


# -----------
# MAIN
rt=0

while [ $# -gt 0 ]; do
    case "$1" in
        'help'|-h|--help)
            echo "$usage"
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
        'version'|-V|--version)
            tdh_version
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
    echo "$usage"
    exit 0
fi

if [[ $ACTION == "pw" ]]; then
    passwd=$( docker logs ${name} 2>&1 | grep GENERATED | awk -F': ' '{ print $2 }' )
    echo " -> Mysqld root password: '$passwd'"
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

echo "
  TDH Docker Container: '${name}'
  Docker Image: ${docker_image}
  Container Volume: '${volname}'
  Docker Network: ${network}
  Local port: ${port}
"

if [[ $ACTION == "run" || $ACTION == "start" ]]; then

    if [ ! -f $mycnf ]; then
        echo "Error locating mysql config: '$mycnf'"
        exit 1
    fi

    echo " -> Starting container '$name'"

    ( $cmd )
    rt=$?
    ( sleep 6 )  # allow mysqld to start and generate password

    if [ $rt -ne 0 ]; then
        echo "Error in docker run"
        exit 1
    fi

    echo -n " -> Checking for password. "
    for x in {1..5}; do
        passwd=$( docker logs ${name} 2>&1 | grep GENERATED | awk -F': ' '{ print $2 }' )
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
    rt=$?
else
    printf "  <DRYRUN> - Command to exec would be: \n\n ( %s )\n" $cmd
fi

if [ $rt -ne 0 ]; then
    echo "$TDH_PNAME ERROR in docker run"
else
    echo "$success"
fi

echo "$PNAME Finished."

exit $rt
