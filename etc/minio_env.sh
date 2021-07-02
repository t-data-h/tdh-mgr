#!/usr/bin/env bash
#
# minio_env.sh  -  MinIO Environment settings and functions
# The following environment variables are supported for scoping 
# the MinIO Environment to a given tenant cluster:
#
#  MINIO_RELEASE_NAME  -  the tenant name for a given deployment
#  MINIO_HOST_ALIAS    -  the cluster alias for `mc`, see `mc alias --help`
#  MINIO_NAMESPACE     -  the MinIO Namespace, 'minio' by default.
#  MINIO_SERVER_PORT   -  the MinIO server port, default is 9000
#  MINIO_GATEWAY_PORT  -  the MinIO HDFS Gateway server port, if applicable
#
# Timothy C. Arland <tcarland@gmail.com>
#
export MINIO_ENV_SH="v21.07"

export MINIO_RELEASE="${MINIO_RELEASE_NAME:-minio-1}"
export MINIO_ALIAS="${MINIO_HOST_ALIAS:-$(hostname -s)}"
export MINIO_NS="${MINIO_NAMESPACE:-minio}"
export MINIO_SERVER_PORT=${MINIO_SERVER_PORT:-9000}
export MINIO_GATEWAY_PORT=${MINIO_HDFS_GATEWAY_PORT:-9001}

# ------------------------

MC="$MINIO_ALIAS"

alias mcmb="mcmkdir"

# ------------------------

function mcrun()
{
    ( mc $1 "${MC}/$2" )
    return $?
}

function mcls()
{
    mcrun "ls" $1
    return $?
}

function mctree()
{
    mcrun "tree" $1
    return $?
}

function mcmkdir()
{
    mcrun "mb" $1
    return $?
}

function mcrm()
{
    mcrun "rm --recursive --force" $1
    return $?
}


# Determines MinIO Endpoint from cluster, optionally returning the internal clusterIP 
function minio_endpoint()
{
    local clusterip="$1"
    local port=$(kubectl get svc $MINIO_RELEASE -n $MINIO_NS --no-headers | awk '{ print $5 }' | sed 's/:.*//g' | sed 's/\/.*//g')
    local type="$(kubectl get svc $MINIO_RELEASE -n $MINIO_NS --no-headers | awk '{ print $2 }')"
    local ip=

    if [[ "$type" == "LoadBalancer" && -z "$clusterip" ]]; then
        ip="$(kubectl get svc $MINIO_RELEASE -n $MINIO_NS --no-headers | awk '{ print $4 }')"
    else
        ip="$(kubectl get svc $MINIO_RELEASE -n $MINIO_NS --no-headers | awk '{ print $3 }')"
    fi
    if [ -z "$ip" ]; then
        return 1
    fi

    export MINIO_ENDPOINT="http://${ip}:${port}"
    printf "%s" $MINIO_ENDPOINT
    return 0
}


function minio_accesskey()
{
    export MINIO_ACCESS_KEY=$(kubectl get secret $MINIO_RELEASE -n $MINIO_NS -o jsonpath="{.data.accesskey}" | base64 --decode)
    printf "%s" $MINIO_ACCESS_KEY
}


function minio_secretkey()
{
    export MINIO_SECRET_KEY=$(kubectl get secret $MINIO_RELEASE -n $MINIO_NS -o jsonpath="{.data.secretkey}" | base64 --decode)
    printf "%s" $MINIO_SECRET_KEY
}


function minio_open()
{
    local rt=0
    local pod=$(kubectl get pods --namespace $MINIO_NS -l "release=${MINIO_RELEASE}" -o jsonpath="{.items[0].metadata.name}")
    
    ( kubectl port-forward $pod $MINIO_SERVER_PORT --namespace $MINIO_NS >/dev/null 2>&1 & )
    
    rt=$?
    printf "MinIO Server UI: http://localhost:${MINIO_SERVER_PORT} \n"
    return $rt
}


function minio_gateway()
{
    ( minio gateway hdfs --address ${MINIO_ALIAS}:${MINIO_GATEWAY_PORT} & )
    sleep 2
    ( mc alias set hdfs http://${MINIO_ALIAS}:${MINIO_GATEWAY_PORT} "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" )
}

# minio_env.sh