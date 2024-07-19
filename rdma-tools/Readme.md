# rdma tools

images including kinds of RDMA tools for debugging

## release chart and images

the image will automatically be generated after the PR is merged to branch main

release the chart 

```shell
git tag rdma-tools-vXX.YY.ZZ 
git push --tags
```

```shell
helm repo add spiderchart https://spidernet-io.github.io/charts
helm repo update
helm search repo rdma-tools

# run daemonset on worker1 and worker2 
cat <<EOF > values.yaml
# for china user , it could add these to use a domestic registry
#image:
#  registry: ghcr.m.daocloud.io
 
# just run daemonset in nodes 'worker1' and 'worker2'
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
              - worker1
              - worker2

# sriov interfaces
extraAnnotations:
  v1.multus-cni.io/default-network: spiderpool/calico
  k8s.v1.cni.cncf.io/networks: |-
      [{"name":"gpu1-sriov","namespace":"spiderpool"},
       {"name":"gpu2-sriov","namespace":"spiderpool"}]

# sriov resource
resources:
  limits:
    spidernet.io/gpu1sriov: 1
    spidernet.io/gpu2sriov: 1
    # nvidia.com/gpu: 1

#securityContext:
#  capabilities:
#    add: [ "IPC_LOCK" ]
EOF

# for China user, add `--set image.registry=ghcr.m.daocloud.io`
helm install rdma-tools spiderchart/rdma-tools -f ./values.yaml

```
