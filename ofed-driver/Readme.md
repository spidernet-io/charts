# ofed driver

refer to nvidia network operator [ofed-driver-ds.yaml](https://github.com/Mellanox/network-operator/blob/master/manifests/state-ofed-driver/0050_ofed-driver-ds.yaml)
and [values.yaml](https://github.com/Mellanox/network-operator/blob/master/deployment/network-operator/values.yaml#L196)

the pod builds the OFED driver from the source and install some online package. Once the pod is ready, the OFED driver is installed


## release chart

```shell
git tag ofe-driver-vXX.YY.ZZ 
git push --tags
```

## deploy 

### image tag

the image tag of ofed-driver has a format `{driverVersion}-${OSName}${OSVer}-${Arch}`.
refer to [nvidia available image tag](https://catalog.ngc.nvidia.com/orgs/nvidia/teams/mellanox/containers/doca-driver/tags)

for example:
- 24.04-0.6.6.0-0-ubuntu20.04-amd64
- 24.04-0.6.6.0-0-ubuntu22.04-amd64
- 24.04-0.6.6.0-0-ubuntu24.04-amd64

### install 

```shell
helm repo add spiderchart https://spidernet-io.github.io/charts
helm repo update
helm search repo ofed-driver

# for China user, add `--set image.registry=nvcr.m.daocloud.io`
helm install ofed-driver spiderchart/ofed-driver -n kube-system \
    --set image.OSName="ubuntu" \
    --set image.OSVer="22.04" \
    --set image.Arch="amd64"
```

note: the pod will run `apt-get` to install something online , you could use proxy as following

```shell
cat<<EOF > values.yaml
image:
  OSName: "ubuntu"
  OSVer: "22.04"
  Arch: "amd64"

extraEnv:
  - name: HTTPS_PROXY 
    value: "http://<example.proxy.com:port>"
  - name: HTTP_PROXY
    value: "http://<example.proxy.com:port>"
  - name: https_proxy
    value: "http://<example.proxy.com:port>"
  - name: http_proxy
    value: "http://<example.proxy.com:port>"
EOF

helm install ofed-driver spiderchart/ofed-driver -n kube-system -f values.yaml

# when the pod is ready, the OFED driver is ready
kubectl get pod -n kube-system 
    kube-system      mofed-ubuntu-24.04-ds-lsprx                                       0/1     Running            0          3m54s

```

when the driver is ready, mlx5_core module could be found on the node
```shell
~# lsmod | grep -i mlx5_core
mlx5_core            2068480  1 mlx5_ib
```

refer [nvidia doc](https://docs.nvidia.com/networking/display/kubernetes2370/network+operator#src-132465565_NetworkOperator-NetworkOperatorDeploymentinAir-gappedEnvironment) and [enviroment config](https://github.com/Mellanox/network-operator/blob/master/docs/mofed-container-env-vars.md) for more details 

