#!/usr/bin/env bash
#
# minio_env.sh  -  MinIO Environment settings and functions
#
# Timothy C. Arland <tcarland@gmail.com>
#
export MINIO_ENV_VERSION="v21.02"

# helm release name
export MINIO_RELEASE="${MINIO_RELEASE_NAME:-minio-1}"
# minio tentant or host alias
export MINIO_ALIAS="${MINIO_HOST_ALIAS:-$(hostname -s)}"
# minio namespace
export MINIO_NS="minio"
# minio server ui port
export MINIO_SERVER_PORT=9000
# minio hdfs gateway
export MINIO_GATEWAY_PORT=9001
# minio root user
#export MINIO_ROOT_USER=minio

# ------------------------

# shell aliases
MC="$MINIO_ALIAS"
alias mcls="mc ls $MC"
alias mccp="mc cp $MC"
alias mccat="mc cat $MC"
alias mcpipe="mc pipe $MC"
alias mcfind="mc find $MC"
alias mctree="mc tree $MC"

# ------------------------

function mcmkdir()
{
    local dir="$1"
    local rt=1

    if [ -n "$dir" ]; then
        ( mc mb $MC/$dir )
        rt=$?
    fi

    return $rt
}

function minio_accesskey()
{
    export MINIO_ACCESS_KEY=$(kubectl get secret $MINIO_RELEASE -n $MINIO_NS -o jsonpath="{.data.accesskey}" | base64 --decode)
}

function minio_secretkey()
{
    export MINIO_SECRET_KEY=$(kubectl get secret $MINIO_RELEASE -n $MINIO_NS -o jsonpath="{.data.secretkey}" | base64 --decode)
}

function minio_open()
{
    rt=0
    export MINIO_POD=$(kubectl get pods --namespace $MINIO_NS -l "release=${MINIO_RELEASE}" -o jsonpath="{.items[0].metadata.name}")
    ( kubectl port-forward $MINIO_POD $MINIO_SERVER_PORT --namespace $MINIO_NS & )
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
