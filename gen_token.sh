#!/bin/bash
set -o pipefail


check_env()
{
    vars=("$@")
    for var in "${vars[@]}"; do
        [ -z "${!var}" ] && echo "Required input $var is unset." && var_unset=true
    done
    [ -n "$var_unset" ] && exit 1
    return 0
}
check_env USERNAME PASSWORD RANCHER_SERVER CLUSTER_NAME

# Use username and passwork to log in Rancher and get a token
get_rancher_token()
{
    curl -s --noproxy '*' -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"username":"'"$USERNAME"'","password":"'"$PASSWORD"'"}' https://$RANCHER_SERVER/v3-public/activeDirectoryProviders/activedirectory?action=login
}

RANCHER_TOKEN=$(get_rancher_token | jq -j .token)

if [ "$?" -eq 6 ]
then 
    echo "error: couldn't resolve host." && exit 1
elif [ "$RANCHER_TOKEN" = "null" ]
then
    HTTP_ERROR=$(get_rancher_token)
    echo $HTTP_ERROR && exit 1
fi

# Get cluster id
CLUSTER_ID=$(curl --noproxy '*' -s -u $RANCHER_TOKEN -X GET https://$RANCHER_SERVER/v3/clusters?name=$CLUSTER_NAME | jq -j .data[0].id)
if [ "$CLUSTER_ID" = "null" ]
then
    echo "error: Input cluster_name is not correct or the cluster is not managed by the input rancher_server." && exit 1
fi

# Get kubeconfig
KUBECONFIG=$(curl --noproxy '*' -s -u $RANCHER_TOKEN https://$RANCHER_SERVER/v3/clusters/$CLUSTER_ID?action=generateKubeconfig -X POST -H 'content-type: application/json' | jq -r .config | base64 -w0)   

# Get access token and api server from kubeconfig
TOKEN=$(echo $KUBECONFIG | base64 -d | awk '/token:/ {print $2}')
SERVER=$(echo $KUBECONFIG | base64 -d | awk '/server:/ {print $2}')
SERVER_RANCHER=$(echo $SERVER | awk '{print $1}')
SERVER_ACE=$(echo $SERVER | awk '{print $2}')

# Set output
echo ::add-mask::$KUBECONFIG
echo ::set-output name=kubeconfig_base64::$KUBECONFIG
echo ::add-mask::$TOKEN
echo ::set-output name=kube_token::$TOKEN
echo ::set-output name=kubeapi_server::$SERVER_RANCHER
echo ::set-output name=kubeapi_server_ace::$SERVER_ACE
echo ::add-mask::$RANCHER_TOKEN
echo ::set-output name=temporary_kube_token::$RANCHER_TOKEN
