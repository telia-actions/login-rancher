# login-rancher Github Action

This action logs in to Rancher and generate a token which can be used to access a Rancher managed kubernetes cluster.

## Inputs

### `cluster_name`
**Required**: Rancher cluster name.

### `rancher_server`
**Required**: FQDN for the Rancher managment server.

### `username`
**Required**: AD account username.

### `password`
**Required**: AD account password.

## Outputs

### `kube_token`: The token that you can use to run kubectl.

### `kubeapi_server`: The default rancher kubeapi_server that you can use to run kubectl.

### `kkubeapi_server_ace`: The Authorized Cluster Endpoints server that you can use to run kubectl.

### `kubeconfig_base64`: The base64 kubeconfig content.

### `temporary_kube_token`: A temporary token that you can use to run kubectl which will be expired (usually after 24 hours).


## Example usage

```yaml
      - id: generate-rancher-auth
        uses: <replace with github repo>/login-rancher
        name: Login
        with:
          cluster_name: workload_cluster_1
          rancher_server: rancher.example.com
          username: ${{ secrets.RANCHER_USER }}
          password: ${{ secrets.RANCHER_PASS }}
```

### Full Example Usage

```yaml
name: Test kubectl running Action

on:
  push:
    branches:
      - main
    
jobs:
  login:
    name: Generate token to access clusters 
    runs-on: [ubuntu-latest]
    steps:
      - uses: actions/checkout@v2 
        name: Checkout  

      - id: generate-rancher-auth
        uses: <replace with github repo>/login-rancher
        name: Login
        with:
          cluster_name: workload_cluster_1
          rancher_server: rancher.example.com
          username: ${{ secrets.RANCHER_USER }}
          password: ${{ secrets.RANCHER_PASS }}

      - name: Setup Kubectl
        uses: telia-actions/setup-kubectl@v1
        with:
            version: 'v*'
        
      - name: Check namespace in the cluster with token and default rancher server
        run: |
          kubectl get namespace \
            --token=${{ steps.generate-rancher-auth.outputs.kube_token }} \
            --server=${{ steps.generate-rancher-auth.outputs.kubeapi_server }}

      - name: Check namespace in the cluster with token and Authorized Cluster Endpoints server
        run: |
          kubectl get namespace \
            --token=${{ steps.generate-rancher-auth.outputs.kube_token }} \
            --server=${{ steps.generate-rancher-auth.outputs.kubeapi_server_ace }} 

      - name: Check namespace in the cluster with temporary token and default rancher server
        run: |
          kubectl get namespace \
            --token=${{ steps.generate-rancher-auth.outputs.temporary_kube_token }} \
            --server=${{ steps.generate-rancher-auth.outputs.kubeapi_server }}

      - name: Check namespace in the cluster with temporary token and Authorized Cluster Endpoints server
        run: |
          kubectl get namespace \
            --token=${{ steps.generate-rancher-auth.outputs.temporary_kube_token }} \
            --server=${{ steps.generate-rancher-auth.outputs.kubeapi_server_ace }} 
```

Recommand to use token as example below. but kubeconfig is also a possible option.
```yaml
      - name: Check namespace in the cluster with kubeconfig
        run: |
          echo ${{ steps.generate-rancher-auth.outputs.kubeconfig_base64 }} | base64 -d > kubeconfig
          export KUBECONFIG=./kubeconfig
          kubectl get namespace
```



