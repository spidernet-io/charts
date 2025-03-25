# rdma tools

images including kinds of RDMA tools for debugging

## image tag

{cuda version of baseImage}-{commit hash of directory}

## chart tag and release chart

the version of chart is '{x of cudaVersion}-{y of cudaVersion}-{custom}'.

For example of chart version 'v12.5.0', '12.5' represents cuda '12.5.x' in the base image, the last '.0' represents any changes of the chart.

tag the code and the CI will automatically release a chart. the image tag will be **chart version** by default.

```shell
git tag rdma-tools-vXX.YY.ZZ 
git push --tags
```

## deploy

```shell
helm repo add spiderchart https://spidernet-io.github.io/charts
helm repo update spiderchart
helm search repo rdma-tools

# run daemonset on worker1 and worker2 
cat <<EOF > values.yaml
# for china user , it could add these to use a domestic registry
image:
  registry: ghcr.m.daocloud.io
  # the default tag is for cuda and nccl, the image is 3G
  #tag: v1.0.0
  # the light tag does not include nccl and cuda, the image is 160 M
  #tag: light-v1.0.0

# just run daemonset in nodes 'worker1' and 'worker2'
# affinity:
#   nodeAffinity:
#     requiredDuringSchedulingIgnoredDuringExecution:
#       nodeSelectorTerms:
#         - matchExpressions:
#           - key: kubernetes.io/hostname
#             operator: In
#             values:
#               - worker1
#               - worker2

# sriov interfaces
extraAnnotations:
  k8s.v1.cni.cncf.io/networks: |-
      [{"name":"gpu1-sriov","namespace":"spiderpool"},
       {"name":"gpu2-sriov","namespace":"spiderpool"}]

# sriov resource
resources:
  limits:
    spidernet.io/gpu1sriov: 1
    spidernet.io/gpu2sriov: 1
    # nvidia.com/gpu: 1

#hostnetwork: false
#ssh_port: 2022

# listen port of http and udp server. Maybe change it in hostnetwork mode
# echo_server_port: 80

securityContext:
  # required by gdrcopy test or hostnetwork
  privileged: true
  capabilities:
    add: [ "IPC_LOCK" ]
EOF

# for China user, add `--set image.registry=ghcr.m.daocloud.io`
helm install rdma-tools spiderchart/rdma-tools -n rdma --create-namespace -f ./values.yaml

```

## tools in the image

os: ubuntu22.04

| tools         | version                                  | updated time |
|---------------|------------------------------------------|--------------|
| cuda          | 12.5.1                                   | 2024.7.30    |
| nccl          | 2.22.3                                   | 2024.7.30    |
| nccl-test     | v2.13.10                                 | 2024.7.30    |
| hpc-x         | v2.19                                    | 2024.7.30    |
| gdrcopy       | 1366e20d140c5638fcaa6c72b373ac69f7ab2532 | 2024.7.30    |
| perftest      | 24.04.0-0.41                             | 2024.7.30    |
| Bandwidthtest | v12.5                                    | 2024.7.30    |
| nvbandwidth   | v0.5                                     | 2024.8.14    |
| tcpdump       | 4.99.5                                   | 2025.2.27    |

## 最佳实践

### NV 环境测试 

* testNcclTest

* testOsu

## echo server

容器中运行了 http 和 udp server 服务，能够回显请求数据

```bash
# Using curl with IPv4 to visit http server
curl -4 http://172.26.85.103

# Using curl with IPv6 to visit http server
curl -6 http://[fc26::8589]

```

```bash
# Using netcat
echo "Hello" | nc -u 172.26.85.103 80

# Using socat with IPv4
echo "Hello" | socat - UDP4:172.26.85.103:80

# Using socat with IPv6
echo "Hello" | socat - UDP6:[fc26::8589]:80

# Using ncat (part of nmap)
echo "Hello" | ncat -u 172.26.85.103 80
```

